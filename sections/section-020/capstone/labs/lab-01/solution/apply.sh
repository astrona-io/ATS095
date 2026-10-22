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

# Step 1: fix the OCIRepository: no tag in the URL, plain HTTP allowed, semver range.
kubectl -n flux-system patch ocirepository podinfo --type=merge -p \
  '{"spec":{"url":"oci://registry.localtest.me:5001/podinfo-manifests","insecure":true,"ref":{"semver":">=1.0.0 <2.0.0"}}}'
flux reconcile source oci podinfo --timeout=2m

# Step 2: make the Flux Kustomization read the OCIRepository.
kubectl -n flux-system patch kustomization podinfo --type=merge -p \
  '{"spec":{"sourceRef":{"kind":"OCIRepository","name":"podinfo"}}}'
flux reconcile kustomization podinfo --timeout=3m
