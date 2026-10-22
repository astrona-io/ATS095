#!/usr/bin/env bash
# Confirms the HelmRepository type matches its address: default with https://, or oci with oci://
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

TYPE="$(field helmrepository podinfo .spec.type)"
URL="$(field helmrepository podinfo .spec.url)"
case "${TYPE:-default}:$URL" in
  default:https://*)
    [ "$(ready helmrepository podinfo)" = "True" ] || fail "the HelmRepository podinfo is not Ready." ;;
  oci:oci://*) ;;
  *) fail "the HelmRepository podinfo has type '${TYPE:-default}' with the address '$URL'; the type must match the address." ;;
esac
echo "PASS: the HelmRepository podinfo has type '${TYPE:-default}' with a matching address."
