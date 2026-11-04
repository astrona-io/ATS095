#!/usr/bin/env bash
# Confirms exactly one --concurrent=8, one --artifact-retention-records=4, one --artifact-retention-ttl=5m and the unchanged --storage-path=/data
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
[ -n "$ARGS" ] || fail "cannot read the args of source-controller."
count() { echo "$ARGS" | jq --arg p "$1" '[.[] | select(startswith($p))] | length'; }
has() { echo "$ARGS" | jq -e --arg a "$1" 'any(.[]; . == $a)' >/dev/null; }
for flag in --concurrent --artifact-retention-records --artifact-retention-ttl; do
  [ "$(count "$flag")" = "1" ] || fail "source-controller has $(count "$flag") arguments that start with $flag; it needs exactly one."
done
has "--concurrent=8" || fail "--concurrent=8 is missing (found: $ARGS)."
has "--artifact-retention-records=4" || fail "--artifact-retention-records=4 is missing."
has "--artifact-retention-ttl=5m" || fail "--artifact-retention-ttl=5m is missing."
has "--storage-path=/data" || fail "--storage-path=/data was removed; keep it."
echo "PASS: source-controller runs with concurrency 8 and retention 4 records for 5m."
