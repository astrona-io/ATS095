#!/usr/bin/env bash
# Confirms the HelmRepository podinfo points at https://stefanprodan.github.io/podinfo and is Ready
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

URL="$(field helmrepository podinfo .spec.url)"
[ "$URL" = "https://stefanprodan.github.io/podinfo" ] || fail "the HelmRepository podinfo points at '$URL'."
[ "$(ready helmrepository podinfo)" = "True" ] || fail "the HelmRepository podinfo is not Ready."
echo "PASS: the HelmRepository podinfo is Ready."
