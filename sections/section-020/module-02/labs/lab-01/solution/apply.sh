#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# Step 1: point the OCIRepository at the Secret.
kubectl -n flux-system patch ocirepository podinfo --type=merge -p '{"spec":{"secretRef":{"name":"regcred"}}}'

# Step 2: replace the Secret with the right password.
kubectl -n flux-system delete secret regcred
flux create secret oci regcred -n flux-system --url=registry.localtest.me:5001 --username=flux --password=registry-password

flux reconcile source oci podinfo --timeout=2m
flux reconcile kustomization podinfo --timeout=3m
