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

# Step 1: follow only 1.x releases, and leave the docs folder out of the artifact.
# spec.ignore replaces the default rules, so it repeats .git/.
kubectl -n flux-system patch gitrepository fleet --type=merge -p \
  '{"spec":{"ref":{"semver":">=1.0.0 <2.0.0"},"ignore":".git/\n/docs/\n"}}'
flux reconcile source git fleet --timeout=2m

# Step 2: apply the 1.2.0 release now.
flux reconcile kustomization podinfo --timeout=4m
