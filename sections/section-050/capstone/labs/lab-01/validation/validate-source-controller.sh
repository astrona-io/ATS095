#!/usr/bin/env bash
# Confirms exactly one --concurrent flag with a value of at least 6, --storage-path=/data and a rolled-out Deployment
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

ARGS="$(kubectl -n flux-system get deployment source-controller -o json | jq -c '.spec.template.spec.containers[0].args')"
N="$(echo "$ARGS" | jq '[.[] | select(startswith("--concurrent"))] | length')"
[ "$N" = "1" ] || fail "source-controller has $N --concurrent arguments; it needs exactly one."
V="$(echo "$ARGS" | jq -r '[.[] | select(startswith("--concurrent="))][0] // empty' | sed 's/--concurrent=//')"
case "$V" in ''|*[!0-9]*) fail "use the form --concurrent=<number> (found: $ARGS).";; esac
[ "$V" -ge 6 ] || fail "--concurrent is $V; the platform team expects 6 sources, so it must be at least 6."
echo "$ARGS" | jq -e 'any(.[]; . == "--storage-path=/data")' >/dev/null || fail "--storage-path=/data was removed."
D="$(field deployment source-controller .spec.replicas)"
A="$(field deployment source-controller .status.availableReplicas)"
U="$(field deployment source-controller .status.updatedReplicas)"
[ "$A" = "$D" ] && [ "$U" = "$D" ] || fail "source-controller is not fully rolled out."
echo "PASS: source-controller reconciles $V sources at a time."
