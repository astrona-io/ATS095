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

# Step 1: read only staging/ and leave the draft out.
kubectl -n flux-system patch bucket releases --type=merge -p \
  '{"spec":{"prefix":"staging/","ignore":"draft/\n"}}'
flux reconcile source bucket releases --timeout=2m

# Step 2: let the Kustomization build and apply staging/.
flux reconcile kustomization releases --timeout=3m
kubectl -n flux-system wait kustomization/releases --for=condition=Ready --timeout=300s
