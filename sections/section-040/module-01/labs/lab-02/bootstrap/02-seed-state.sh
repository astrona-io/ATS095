#!/usr/bin/env bash
# Creates the starting state for ats-095-lab-040-01-02: the bucket "releases"
# with a staging/ and a prod/ folder (and a draft inside staging/), plus a
# Bucket that reads all of it and a Kustomization that fails on the draft.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

s3() {
  # s3 ARGS...: runs `aws s3 ARGS` in the s3-client pod.
  kubectl -n s3 exec -i deploy/s3-client -- aws s3 "$@"
}

echo "[lab] Creating the bucket releases and uploading staging/ and prod/..."
s3 ls s3://releases >/dev/null 2>&1 || s3 mb s3://releases
for key in staging/namespace.yaml staging/deployment.yaml staging/service.yaml staging/draft/deployment.yaml \
           prod/namespace.yaml prod/deployment.yaml prod/service.yaml; do
  s3 cp - "s3://releases/$key" < "$MANIFESTS/bucket/$key"
done

echo "[lab] Creating the Secret, the Bucket releases and the Flux Kustomization releases..."
kubectl apply -f "$MANIFESTS/start/flux-start.yaml"
echo "[lab] Starting state ready. The Kustomization cannot build staging/ yet."
