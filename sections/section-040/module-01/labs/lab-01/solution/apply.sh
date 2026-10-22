#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
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
# Step 1: the Secret and the Bucket source, plus the Flux Kustomization.
kubectl -n flux-system create secret generic s3-credentials \
  --from-literal=accesskey=flux-s3 --from-literal=secretkey=flux-s3-secret \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$MANIFESTS/solution/bucket-podinfo.yaml"
kubectl -n flux-system wait bucket/podinfo --for=condition=Ready --timeout=180s
kubectl -n flux-system wait kustomization/podinfo --for=condition=Ready --timeout=300s

# Step 2: upload a change: 3 replicas.
s3 cp s3://podinfo/deployment.yaml - | sed 's/replicas: 2/replicas: 3/' | s3 cp - s3://podinfo/deployment.yaml

# Step 3: fetch and apply it now, without waiting 30 minutes.
flux reconcile source bucket podinfo --timeout=2m
flux reconcile kustomization podinfo --timeout=3m
