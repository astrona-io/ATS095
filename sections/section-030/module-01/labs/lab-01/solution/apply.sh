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

# The HelmRepository has the default type, which downloads an index.yaml, but
# points at an OCI registry. Point it at the HTTP chart repository instead.
kubectl -n flux-system patch helmrepository podinfo --type=merge -p \
  '{"spec":{"url":"https://stefanprodan.github.io/podinfo"}}'
flux reconcile source helm podinfo --timeout=2m
flux reconcile source chart podinfo --timeout=2m
