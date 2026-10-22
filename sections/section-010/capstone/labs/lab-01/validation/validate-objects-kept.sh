#!/usr/bin/env bash
# Confirms the GitRepository and the Flux Kustomization were fixed in place, not deleted and recreated
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

for kind in gitrepository kustomization; do
  name=fleet; [ "$kind" = kustomization ] && name=podinfo
  want="$(kubectl -n flux-system get configmap capstone-baseline -o jsonpath="{.data.$kind}" 2>/dev/null)"
  have="$(field "$kind" "$name" .metadata.uid)"
  [ -n "$want" ] && [ "$want" = "$have" ] || fail "the $kind $name was deleted and recreated. Fix it in place."
done
echo "PASS: both objects were fixed in place."
