#!/usr/bin/env bash
# Confirms the HelmRelease podinfo is Ready and podinfo runs in the namespace podinfo
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

[ "$(ready helmrelease podinfo)" = "True" ] || fail "the HelmRelease podinfo is not Ready."
READY_REPLICAS="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
[ "${READY_REPLICAS:-0}" -ge 1 ] 2>/dev/null || fail "the Deployment podinfo in the namespace podinfo has no ready replica."
echo "PASS: the HelmRelease podinfo is Ready and podinfo runs."
