#!/usr/bin/env bash
# Creates the starting state for ats-095-lab-040-02: the bucket podinfo with
# the podinfo manifests. The Flux objects exist; the webhook is the task.
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

fill_bucket() {
  # fill_bucket BUCKET: creates BUCKET and uploads the files of manifests/bucket.
  local bucket="$1" file
  s3 ls "s3://$bucket" >/dev/null 2>&1 || s3 mb "s3://$bucket"
  for file in namespace.yaml deployment.yaml service.yaml kustomization.yaml; do
    s3 cp - "s3://$bucket/$file" < "$MANIFESTS/bucket/$file"
  done
}

echo "[lab] Creating the bucket podinfo and uploading the podinfo manifests (2 replicas)..."
fill_bucket podinfo
echo "[lab] Creating the Secret, the Bucket podinfo and the Flux Kustomization podinfo..."
kubectl apply -f "$MANIFESTS/start/flux-start.yaml"
kubectl -n flux-system wait bucket/podinfo --for=condition=Ready --timeout=180s
kubectl -n flux-system wait kustomization/podinfo --for=condition=Ready --timeout=300s
echo "[lab] Starting state ready: podinfo runs 2 replicas, the Bucket checks every 30 minutes."
