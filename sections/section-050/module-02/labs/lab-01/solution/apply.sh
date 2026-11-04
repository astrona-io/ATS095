#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"


kubectl -n flux-system get deployment source-controller -o json | jq '
  .spec.template.spec.containers[0] |=
    ( .args |= ( map(select((startswith("--concurrent") or startswith("--artifact-retention")) | not))
                 + ["--concurrent=8","--artifact-retention-records=4","--artifact-retention-ttl=5m"] )
    | .resources.requests.memory = "256Mi"
    | .resources.limits.memory = "2Gi" )' | kubectl replace -f -
kubectl -n flux-system rollout status deployment/source-controller --timeout=180s
kubectl -n flux-system wait gitrepository/fleet --for=condition=Ready --timeout=180s
kubectl -n flux-system wait kustomization/podinfo --for=condition=Ready --timeout=300s
