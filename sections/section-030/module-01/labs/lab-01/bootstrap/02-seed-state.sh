#!/usr/bin/env bash
# Creates the starting state for ats-095-lab-030-01: a HelmRepository of the
# default type that points at an oci:// address, and a HelmChart that uses it.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Applying the HelmRepository and the HelmChart..."
kubectl apply -f "$MANIFESTS/helm-sources.yaml"
sleep 10
kubectl -n flux-system create configmap lab-baseline \
  --from-literal=helmrepository="$(kubectl -n flux-system get helmrepository podinfo -o jsonpath='{.metadata.uid}')" \
  --from-literal=helmchart="$(kubectl -n flux-system get helmchart podinfo -o jsonpath='{.metadata.uid}')" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready. The chart does not resolve."
flux get sources helm || true
flux get sources chart || true
