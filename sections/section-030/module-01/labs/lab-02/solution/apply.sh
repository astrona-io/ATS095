#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# Two faults: the chart name is misspelled and the version range has no match.
kubectl -n flux-system patch helmchart podinfo --type=merge -p \
  '{"spec":{"chart":"podinfo","version":"6.x"}}'
flux reconcile source chart podinfo --with-source --timeout=2m
