#!/usr/bin/env bash
# Installs the Flux CLI 2.9.6 and controllers, an OCI registry, and the
# CoreDNS rewrite for registry.localtest.me.
#
# Graded lab bootstrap: this prepares the environment ONLY.
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
  echo "[lab] Downloading Flux CLI ${FLUX_VERSION} (${OS}/${ARCH})..."
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
    echo "[lab] Adding CoreDNS rewrites: $*"
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

echo "[lab] Applying the starting workloads..."
kubectl apply -f "$MANIFESTS/lab-start.yaml"
kubectl -n registry rollout status deployment/registry --timeout=300s

add_coredns_rewrites registry.localtest.me=registry.registry.svc.cluster.local

echo "[lab] Installing the Flux controllers..."
flux install
flux check

