#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# Fault 1: the Secret name. The working Secret is fleet-auth.
kubectl -n flux-system patch gitrepository fleet --type=merge -p \
  '{"spec":{"secretRef":{"name":"fleet-auth"}}}'

# Fault 2: the branch. gitops/fleet has main, not release.
kubectl -n flux-system patch gitrepository fleet --type=merge -p \
  '{"spec":{"ref":{"branch":"main"}}}'

flux reconcile source git fleet --timeout=2m
flux reconcile kustomization podinfo --timeout=3m
