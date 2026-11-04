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
  .spec.template.spec.containers[0].args |=
    (map(select(startswith("--concurrent") | not)) + ["--concurrent=6"])' | kubectl replace -f -
kubectl -n flux-system rollout status deployment/source-controller --timeout=180s
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"ref":{"branch":"main"}}}'
flux resume source git platform
flux reconcile source git fleet --timeout=2m
flux reconcile source git platform --timeout=2m
flux create secret git fleet-auth -n team-b \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git --username=gitops --password=gitops-password
flux create source git fleet -n team-b \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git --branch=main --secret-ref=fleet-auth --interval=1m
kubectl -n team-b wait gitrepository/fleet --for=condition=Ready --timeout=180s
kubectl -n team-b patch kustomization team-b-apps --type=merge -p \
  '{"spec":{"serviceAccountName":"team-b","sourceRef":{"kind":"GitRepository","name":"fleet","namespace":"team-b"}}}'
flux reconcile kustomization podinfo --timeout=3m
flux reconcile kustomization platform-settings --timeout=3m
flux reconcile kustomization team-b-apps -n team-b --timeout=3m
