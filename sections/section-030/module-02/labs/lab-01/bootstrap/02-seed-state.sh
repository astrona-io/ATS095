#!/usr/bin/env bash
# Creates the starting state for ats-095-lab-030-02: a GitRepository on a
# branch that does not exist, and a HelmChart with a wrong chart path and the
# default reconcileStrategy.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Applying the GitRepository and the HelmChart..."
kubectl apply -f "$MANIFESTS/git-chart.yaml"
sleep 10
kubectl -n flux-system create configmap lab-baseline \
  --from-literal=gitrepository="$(kubectl -n flux-system get gitrepository podinfo-git -o jsonpath='{.metadata.uid}')" \
  --from-literal=helmchart="$(kubectl -n flux-system get helmchart podinfo-git -o jsonpath='{.metadata.uid}')" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready. The chart does not build."
flux get sources git || true
flux get sources chart || true
