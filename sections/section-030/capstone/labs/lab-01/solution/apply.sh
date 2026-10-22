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

# Step 1: fix the repository address.
kubectl -n flux-system patch helmrepository podinfo --type=merge -p \
  '{"spec":{"url":"https://stefanprodan.github.io/podinfo"}}'
flux reconcile source helm podinfo --timeout=2m

# Step 2: point the HelmRelease at that repository, with a range that exists.
kubectl -n flux-system patch helmrelease podinfo --type=merge -p \
  '{"spec":{"chart":{"spec":{"version":"6.x","sourceRef":{"kind":"HelmRepository","name":"podinfo"}}}}}'
flux reconcile helmrelease podinfo --with-source --timeout=5m
kubectl -n podinfo rollout status deployment/podinfo --timeout=300s
