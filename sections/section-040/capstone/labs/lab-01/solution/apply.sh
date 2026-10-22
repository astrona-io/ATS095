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

# Step 1: the Secret keys must be accesskey and secretkey.
kubectl -n flux-system delete secret s3-credentials --ignore-not-found
kubectl -n flux-system create secret generic s3-credentials \
  --from-literal=accesskey=flux-s3 --from-literal=secretkey=flux-s3-secret

# Step 2: the right bucket, over plain HTTP.
kubectl -n flux-system patch bucket podinfo --type=merge -p \
  '{"spec":{"bucketName":"podinfo","insecure":true}}'
flux reconcile source bucket podinfo --timeout=2m

# Step 3: the manifests are at the root of the bucket.
kubectl -n flux-system patch kustomization podinfo --type=merge -p '{"spec":{"path":"./"}}'
flux reconcile kustomization podinfo --timeout=3m
