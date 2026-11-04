#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# Step 1: fix the repository name.
kubectl -n flux-system patch ocirepository podinfo --type=merge -p \
  '{"spec":{"url":"oci://registry.localtest.me:5001/podinfo-manifests"}}'
# Step 2: allow the plain HTTP registry.
kubectl -n flux-system patch ocirepository podinfo --type=merge -p '{"spec":{"insecure":true}}'
# Step 3: use the tag that exists.
kubectl -n flux-system patch ocirepository podinfo --type=merge -p '{"spec":{"ref":{"tag":"1.1.0"}}}'

flux reconcile source oci podinfo --timeout=2m
flux reconcile kustomization podinfo --timeout=3m
