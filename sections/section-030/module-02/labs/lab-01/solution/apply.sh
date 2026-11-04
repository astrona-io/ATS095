#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# The repository's default branch is master, not main.
kubectl -n flux-system patch gitrepository podinfo-git --type=merge -p \
  '{"spec":{"ref":{"branch":"master"}}}'
flux reconcile source git podinfo-git --timeout=2m
# The chart directory is charts/podinfo, and the chart must be rebuilt on every commit.
kubectl -n flux-system patch helmchart podinfo-git --type=merge -p \
  '{"spec":{"chart":"./charts/podinfo","reconcileStrategy":"Revision"}}'
flux reconcile source chart podinfo-git --with-source --timeout=2m
