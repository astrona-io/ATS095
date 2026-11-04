#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"


kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"ref":{"branch":"main"}}}'
flux create secret git platform-auth \
  --url=http://gitea.localtest.me:3000/gitops/platform.git \
  --username=gitops --password=gitops-password --export | kubectl apply -f -
flux resume source git fleet-tags
flux reconcile source git fleet --timeout=2m
flux reconcile source git platform --timeout=2m
flux reconcile source git fleet-tags --timeout=2m
flux reconcile kustomization podinfo --timeout=3m
flux reconcile kustomization platform-settings --timeout=3m
