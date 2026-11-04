#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# Step 1: remove ref.name so branch main is used again.
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"ref":{"name":null}}}'

# Step 2: check out the directory apps as well.
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"sparseCheckout":["apps","clusters"]}}'

flux reconcile source git fleet --timeout=2m
flux reconcile kustomization podinfo --timeout=3m
