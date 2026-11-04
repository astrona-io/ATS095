#!/usr/bin/env bash
# Creates the starting state for ats-095-lab-010-03: the GitRepository fleet
# checks out only the directory clusters and follows a reference that does not
# exist. Two faults, both visible on fleet and on the Flux Kustomization.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Creating the Secret fleet-auth with the Gitea credentials..."
kubectl -n flux-system create secret generic fleet-auth \
  --from-literal=username=gitops --from-literal=password=gitops-password

kubectl apply -f "$MANIFESTS/flux-sync.yaml"
sleep 10

echo "[lab] Starting state ready: fleet cannot fetch the right content."
flux get sources git || true
flux get kustomizations || true
