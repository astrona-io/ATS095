#!/usr/bin/env bash
# Creates the starting state for ats-095-capstone-020: three releases in the
# registry, an OCIRepository with a tag in its URL and no insecure setting,
# and a Flux Kustomization that names a GitRepository.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

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

echo "[lab] Pushing podinfo-manifests 1.0.0, 1.1.0 and 2.0.0..."
start_port_forward registry registry "5001:5001" http://registry.localtest.me:5001/v2/
SOURCE_URL="https://example.com/podinfo-manifests"
SOURCE_REVISION="main@sha1:0000000000000000000000000000000000000000"
push_release 1.0.0 1
push_release 1.1.0 3
push_release 2.0.0 5

echo "[lab] Applying the broken OCI delivery..."
kubectl apply -f "$MANIFESTS/flux-sync.yaml"
sleep 10
kubectl -n flux-system create configmap capstone-baseline \
  --from-literal=ocirepository="$(kubectl -n flux-system get ocirepository podinfo -o jsonpath='{.metadata.uid}')" \
  --from-literal=kustomization="$(kubectl -n flux-system get kustomization podinfo -o jsonpath='{.metadata.uid}')" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready. Nothing is deployed."
flux get sources oci || true
flux get kustomizations || true
