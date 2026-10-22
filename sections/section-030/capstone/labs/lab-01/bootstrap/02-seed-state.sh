#!/usr/bin/env bash
# Creates the starting state for ats-095-capstone-030: a HelmRepository with a
# wrong address, and a HelmRelease that names a repository that does not
# exist and a chart version range with no match.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Applying the HelmRepository and the HelmRelease..."
kubectl apply -f "$MANIFESTS/helm-release.yaml"
sleep 10
kubectl -n flux-system create configmap capstone-baseline \
  --from-literal=helmrepository="$(kubectl -n flux-system get helmrepository podinfo -o jsonpath='{.metadata.uid}')" \
  --from-literal=helmrelease="$(kubectl -n flux-system get helmrelease podinfo -o jsonpath='{.metadata.uid}')" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready. podinfo is not installed."
flux get sources helm || true
flux get helmreleases || true
