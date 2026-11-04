#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"


API="http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/contents/apps/podinfo/deployment.yaml"
kubectl -n gitea exec deploy/tester -- sh -c '
  API="'"$API"'"
  J="$(curl -fsS -u gitops:gitops-password "$API")"
  SHA="$(echo "$J" | jq -r .sha)"
  NEW="$(echo "$J" | jq -r .content | base64 -d | sed "s/replicas: 2/replicas: 4/" | base64 | tr -d "\n")"
  curl -fsS -u gitops:gitops-password -X PUT -H "Content-Type: application/json" \
    -d "{\"content\":\"$NEW\",\"message\":\"Scale podinfo to 4 replicas\",\"branch\":\"main\",\"sha\":\"$SHA\"}" "$API" >/dev/null'

flux reconcile source git fleet --timeout=2m
flux reconcile kustomization podinfo --timeout=3m

URL="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.url}')"
REV="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.revision}')"
DIGEST="$(kubectl -n flux-system exec deploy/artifact-reader -- sh -c "curl -s '$URL' | sha256sum | cut -d' ' -f1")"
FILES="$(kubectl -n flux-system exec deploy/artifact-reader -- sh -c "curl -s '$URL' | tar -tvzf - | grep -c '^-'")"
kubectl -n flux-system create configmap artifact-proof \
  --from-literal=revision="$REV" --from-literal=digest="sha256:$DIGEST" --from-literal=files="$FILES"
