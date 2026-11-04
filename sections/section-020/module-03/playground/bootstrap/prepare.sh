#!/usr/bin/env bash
# OS prep for the "Work With Flux Artifacts From The Command Line" playground (`ats-095-playground-020-03`).
#
# Environment preparation only. There is no task and no grading. It installs
# the Flux CLI and controllers, Gitea with gitops/fleet, and an OCI registry,
# and pushes two releases of the podinfo manifests to the registry.
set -euo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

FLUX_VERSION="2.9.6"
BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# Pin the version rather than accepting whatever flux happens to be on the
# machine: the CLI installs controllers of its own version, and the course is
# written against ${FLUX_VERSION}.
have_version=""
command -v flux >/dev/null 2>&1 && \
  have_version=$(flux version --client 2>/dev/null | awk '/flux:/{print $2}' | sed 's/^v//')
if [ "$have_version" != "$FLUX_VERSION" ]; then
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"
  case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
  WORK="$(mktemp -d)"
  trap 'rm -rf "$WORK"' EXIT
  echo "[playground] Downloading Flux CLI ${FLUX_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_${OS}_${ARCH}.tar.gz" \
    | tar -xz -C "$WORK" flux
  install -m 0755 "$WORK/flux" "$BIN_DIR/flux"
fi
flux version --client

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

add_coredns_rewrites() {
  # add_coredns_rewrites NAME=SERVICE_FQDN ...: makes each public name resolve
  # to an in-cluster Service. The answer is rewritten back to the asked name:
  # Go programs such as the Flux controllers ignore DNS answers whose name
  # differs from the question.
  local corefile blocks pair name target name_regex target_regex
  corefile="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}')"
  blocks="$(mktemp)"
  for pair in "$@"; do
    name="${pair%%=*}"
    target="${pair#*=}"
    name_regex="$(printf '%s' "$name" | sed 's/\./\\./g')"
    target_regex="$(printf '%s' "$target" | sed 's/\./\\./g')"
    printf '%s' "$corefile" | grep -qF "answer name ${target_regex} ${name}" && continue
    {
      echo "    rewrite stop {"
      echo "        name regex ${name_regex} ${target}"
      echo "        answer name ${target_regex} ${name}"
      echo "    }"
    } >> "$blocks"
  done
  if [ -s "$blocks" ]; then
    echo "[playground] Adding CoreDNS rewrites: $*"
    corefile="$(printf '%s\n' "$corefile" | awk -v blocks="$blocks" '
      /^[[:space:]]*kubernetes / && !done { while ((getline line < blocks) > 0) print line; done=1 }
      { print }')"
    kubectl -n kube-system create configmap coredns --from-literal=Corefile="$corefile" \
      --dry-run=client -o yaml | kubectl apply -f -
    kubectl -n kube-system rollout restart deployment/coredns
    kubectl -n kube-system rollout status deployment/coredns --timeout=120s
  fi
  rm -f "$blocks"
}

GIT_USER="gitops"
GIT_PASSWORD="gitops-password"
REPO="fleet"

gitea_api() {
  # gitea_api METHOD PATH [JSON]: calls the Gitea API from the tester pod.
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    printf '%s' "$body" | kubectl -n gitea exec -i deploy/tester -- \
      curl -fsS -u "$GIT_USER:$GIT_PASSWORD" -X "$method" -H 'Content-Type: application/json' \
      --data-binary @- "http://gitea-http.gitea:3000/api/v1$path"
  else
    kubectl -n gitea exec deploy/tester -- \
      curl -fsS -u "$GIT_USER:$GIT_PASSWORD" -X "$method" "http://gitea-http.gitea:3000/api/v1$path"
  fi
}

put_file() {
  # put_file REPO PATH MESSAGE < CONTENT: creates or updates one file on main.
  local repo="$1" path="$2" message="$3" content sha
  content="$(base64 | tr -d '\n')"
  sha="$(kubectl -n gitea exec deploy/tester -- sh -c \
    "curl -fsS -u '$GIT_USER:$GIT_PASSWORD' http://gitea-http.gitea:3000/api/v1/repos/$GIT_USER/$repo/contents/$path 2>/dev/null | jq -r '.sha // empty'" || true)"
  if [ -n "$sha" ]; then
    gitea_api PUT "/repos/$GIT_USER/$repo/contents/$path" \
      "{\"content\":\"$content\",\"message\":\"$message\",\"branch\":\"main\",\"sha\":\"$sha\"}" >/dev/null
  else
    gitea_api POST "/repos/$GIT_USER/$repo/contents/$path" \
      "{\"content\":\"$content\",\"message\":\"$message\",\"branch\":\"main\"}" >/dev/null
  fi
}

create_tag() {
  # create_tag REPO TAG: tags the current head of main.
  gitea_api POST "/repos/$GIT_USER/$1/tags" "{\"tag_name\":\"$2\",\"target\":\"main\"}" >/dev/null
}

main_commit() {
  # main_commit REPO: prints the commit id at the head of main.
  kubectl -n gitea exec deploy/tester -- sh -c \
    "curl -fsS -u '$GIT_USER:$GIT_PASSWORD' http://gitea-http.gitea:3000/api/v1/repos/$GIT_USER/$1/branches/main | jq -r .commit.id"
}

create_repo_from_dir() {
  # create_repo_from_dir REPO DIR: creates a private repository and commits
  # every file of DIR to main, unless the repository already holds files.
  local repo="$1" dir="$2" file
  gitea_api GET "/repos/$GIT_USER/$repo" >/dev/null 2>&1 || \
    gitea_api POST "/user/repos" "{\"name\":\"$repo\",\"auto_init\":true,\"default_branch\":\"main\",\"private\":true}" >/dev/null
  if gitea_api GET "/repos/$GIT_USER/$repo/contents/apps" >/dev/null 2>&1; then
    return 0
  fi
  (cd "$dir" && find . -type f | sed 's|^\./||' | sort) | while read -r file; do
    put_file "$repo" "$file" "Add $file" < "$dir/$file"
  done
}

echo "[playground] Applying the starting workloads..."
kubectl apply -f "$MANIFESTS/lab-start.yaml"
kubectl -n gitea rollout status deployment/gitea --timeout=300s
kubectl -n gitea rollout status deployment/tester --timeout=300s
kubectl apply -f "$MANIFESTS/registry.yaml"
kubectl -n registry rollout status deployment/registry --timeout=300s

# One address for the machine and the cluster: each *.localtest.me name
# resolves to 127.0.0.1 on the machine (reached through a port-forward)
# and to its Service inside the cluster.
add_coredns_rewrites gitea.localtest.me=gitea-http.gitea.svc.cluster.local registry.localtest.me=registry.registry.svc.cluster.local

echo "[playground] Creating the Gitea user ${GIT_USER}..."
for _ in $(seq 1 30); do
  kubectl -n gitea exec deploy/gitea -- gitea admin user create \
    --username "$GIT_USER" --password "$GIT_PASSWORD" --email gitops@example.com \
    --admin --must-change-password=false >/dev/null 2>&1 && break
  gitea_api GET "/user" >/dev/null 2>&1 && break
  sleep 2
done
echo "[playground] Seeding the repository ${GIT_USER}/${REPO}..."
create_repo_from_dir "$REPO" "$MANIFESTS/repo"

echo "[playground] Installing the Flux controllers..."
flux install
flux check

PORT_FORWARD_PIDS=""
stop_port_forwards() {
  for pid in $PORT_FORWARD_PIDS; do kill "$pid" 2>/dev/null || true; done
  # Also remove the Flux CLI download folder, whose own EXIT trap this replaces.
  [ -n "${WORK:-}" ] && rm -rf "$WORK"
  return 0
}
trap stop_port_forwards EXIT

start_port_forward() {
  # start_port_forward NAMESPACE SERVICE PORTS CHECK_URL: runs a port-forward in
  # the background and waits until CHECK_URL answers on this machine. A learner
  # runs the same port-forward in a second terminal. If the *.localtest.me name
  # does not resolve to 127.0.0.1 here, add it to /etc/hosts.
  local namespace="$1" service="$2" ports="$3" check_url="$4"
  # shellcheck disable=SC2086
  kubectl -n "$namespace" port-forward "svc/$service" $ports >/dev/null 2>&1 &
  PORT_FORWARD_PIDS="$PORT_FORWARD_PIDS $!"
  for _ in $(seq 1 30); do
    curl -fsS "$check_url" >/dev/null 2>&1 && return 0
    sleep 1
  done
  echo "ERROR: $check_url does not answer through the port-forward." >&2
  echo "If the name does not resolve to 127.0.0.1 here, add it to /etc/hosts:" >&2
  echo "  127.0.0.1 gitea.localtest.me registry.localtest.me" >&2
  return 1
}

push_release() {
  # push_release VERSION REPLICAS: pushes apps/podinfo with REPLICAS replicas
  # as oci://registry.localtest.me:5001/podinfo-manifests:VERSION.
  local version="$1" replicas="$2" dir
  dir="$(mktemp -d)"
  cp "$MANIFESTS/repo/apps/podinfo/"*.yaml "$dir/"
  sed -i.bak "s/replicas: [0-9]*/replicas: $replicas/" "$dir/deployment.yaml" && rm -f "$dir/deployment.yaml.bak"
  flux push artifact "oci://registry.localtest.me:5001/podinfo-manifests:$version" \
    --path="$dir" --source="$SOURCE_URL" --revision="$SOURCE_REVISION" --insecure-registry
  rm -rf "$dir"
}

echo "[playground] Pushing podinfo-manifests 1.0.0 (1 replica) and 1.1.0 (3 replicas)..."
start_port_forward registry registry "5001:5001" http://registry.localtest.me:5001/v2/
SOURCE_URL="http://gitea.localtest.me:3000/gitops/fleet.git"
SOURCE_REVISION="main@sha1:$(main_commit "$REPO")"
push_release 1.0.0 1
push_release 1.1.0 3

echo "[playground] Ready."
echo "[playground] Start the port-forwards in a second terminal before you use git or push:"
echo "  kubectl -n gitea port-forward svc/gitea-http 3000:3000"
echo "  kubectl -n registry port-forward svc/registry 5001:5001"
