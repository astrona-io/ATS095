#!/usr/bin/env bash
# Confirms the artifact of fleet holds apps/podinfo and no docs folder
set -uo pipefail

ready() {
  # ready KIND NAME: prints the status of the Ready condition in flux-system.
  kubectl -n flux-system get "$1" "$2" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null
}
field() {
  # field KIND NAME JSONPATH: prints one field of an object in flux-system.
  kubectl -n flux-system get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null
}
fail() { echo "FAIL: $*"; exit 1; }

URL="$(field gitrepository fleet .status.artifact.url)"
[ -n "$URL" ] || fail "fleet has no artifact."
# Network policies allow traffic to source-controller only from flux-system,
# so the artifact is read by a short-lived pod there.
FILES="$(kubectl -n flux-system run "grader-artifact-$$" --rm -i --restart=Never --quiet \
  --image=nicolaka/netshoot:v0.13 -- sh -c "curl -fsS '$URL' | tar -tzf -" 2>/dev/null)"
[ -n "$FILES" ] || fail "could not list the files in the artifact of fleet."
printf '%s\n' "$FILES" | grep -q 'apps/podinfo/deployment.yaml' || fail "the artifact no longer holds apps/podinfo."
printf '%s\n' "$FILES" | grep -q 'docs/' && fail "the artifact still holds the docs folder."
echo "PASS: the artifact holds apps/podinfo and no docs folder."
