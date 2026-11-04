#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"


flux create secret git fleet-auth -n team-a \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password
flux create source git fleet -n team-a \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --branch=main --secret-ref=fleet-auth --interval=1m
kubectl -n team-a wait gitrepository/fleet --for=condition=Ready --timeout=180s
kubectl -n team-a patch kustomization team-a-apps --type=merge -p \
  '{"spec":{"serviceAccountName":"team-a","sourceRef":{"kind":"GitRepository","name":"fleet","namespace":"team-a"}}}'
flux reconcile kustomization team-a-apps -n team-a --timeout=3m
