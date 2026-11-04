#!/usr/bin/env bash
# Confirms the memory request is 256Mi and the memory limit 2Gi on the source-controller container
set -uo pipefail

ready() {
  # ready KIND NAME [NAMESPACE]: prints the status of the Ready condition.
  kubectl -n "${3:-flux-system}" get "$1" "$2" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null
}
field() {
  # field KIND NAME JSONPATH [NAMESPACE]: prints one field of an object.
  kubectl -n "${4:-flux-system}" get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null
}
fail() { echo "FAIL: $*"; exit 1; }

P='.spec.template.spec.containers[0].resources'
REQ="$(field deployment source-controller "$P.requests.memory")"
LIM="$(field deployment source-controller "$P.limits.memory")"
[ "$REQ" = "256Mi" ] || fail "memory request is '${REQ:-unset}'; it should be 256Mi."
[ "$LIM" = "2Gi" ] || fail "memory limit is '${LIM:-unset}'; it should be 2Gi."
echo "PASS: memory request 256Mi, limit 2Gi."
