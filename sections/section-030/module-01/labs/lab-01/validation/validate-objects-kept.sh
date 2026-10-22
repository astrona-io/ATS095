#!/usr/bin/env bash
# Confirms the HelmRepository and the HelmChart were fixed in place
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

for kind in helmrepository helmchart; do
  want="$(kubectl -n flux-system get configmap lab-baseline -o jsonpath="{.data.$kind}" 2>/dev/null)"
  have="$(field "$kind" podinfo .metadata.uid)"
  [ -n "$want" ] && [ "$want" = "$have" ] || fail "the $kind podinfo was deleted and recreated. Fix it in place."
done
echo "PASS: both objects were fixed in place."
