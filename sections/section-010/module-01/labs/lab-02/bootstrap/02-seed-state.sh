#!/usr/bin/env bash
# Creates the starting state for ats-095-lab-010-01-02: the GitRepository fleet
# is broken in two places. It follows the branch release, which does not exist
# in gitops/fleet, and its secretRef names fleet-credentials, which does not
# exist. The Secret with the working credentials is fleet-auth. The fault is
# the material: this script never repairs it.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

GIT_USER="gitops"
GIT_PASSWORD="gitops-password"

echo "[lab] Creating the working credentials as the Secret fleet-auth..."
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username="$GIT_USER" --password="$GIT_PASSWORD"

echo "[lab] Applying the broken GitRepository fleet and the Kustomization podinfo..."
kubectl apply -f "$MANIFESTS/flux-sync.yaml"

# Wait until source-controller has handled the object once, so the learner
# finds a failure message in the status. The wait does not require success.
for _ in $(seq 1 60); do
  READY="$(kubectl -n flux-system get gitrepository fleet \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  [ "$READY" = "False" ] && break
  sleep 2
done

echo "[lab] Starting state ready: fleet is not Ready and podinfo is not deployed."
flux get sources git || true
echo "[lab] Finding the cause in the status and fixing it is the task."
