#!/usr/bin/env bash
# Creates the starting state for ats-095-lab-020-03: two releases of the
# podinfo manifests in the registry and an OCIRepository fixed to tag 1.1.0.
# The task is to release 1.2.0 from main with the flux CLI and pin the digest.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

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

echo "[lab] Pushing podinfo-manifests 1.0.0 and 1.1.0..."
start_port_forward registry registry "5001:5001" http://registry.localtest.me:5001/v2/
SOURCE_URL="http://gitea.localtest.me:3000/gitops/fleet.git"
SOURCE_REVISION="main@sha1:$(main_commit "$REPO")"
push_release 1.0.0 1
push_release 1.1.0 3

echo "[lab] Pointing Flux at the fixed tag 1.1.0..."
kubectl apply -f "$MANIFESTS/flux-sync.yaml"
kubectl -n flux-system wait ocirepository/podinfo --for=condition=Ready --timeout=180s || true
kubectl -n flux-system wait kustomization/podinfo --for=condition=Ready --timeout=300s || true

echo "[lab] Starting state ready: podinfo runs release 1.1.0 (3 replicas); main asks for 2."
flux get sources oci || true
