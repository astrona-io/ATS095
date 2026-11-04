#!/usr/bin/env bash
# Recomputes the sha256 digest and the file count from the served artifact and compares them with artifact-proof
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

CM() { kubectl -n flux-system get configmap artifact-proof -o "jsonpath={.data.$1}" 2>/dev/null; }
URL="$(field gitrepository fleet .status.artifact.url)"
[ -n "$URL" ] || fail "fleet has no artifact URL."
STATUS_DIGEST="$(field gitrepository fleet .status.artifact.digest)"
[ "$(CM digest)" = "$STATUS_DIGEST" ] || fail "digest '$(CM digest)' does not match status.artifact.digest '$STATUS_DIGEST'."
CALC="sha256:$(kubectl -n flux-system exec deploy/artifact-reader -- sh -c "curl -s '$URL' | sha256sum | cut -d' ' -f1")"
[ "$(CM digest)" = "$CALC" ] || fail "digest '$(CM digest)' is not the sha256 of the served file ('$CALC')."
COUNT="$(kubectl -n flux-system exec deploy/artifact-reader -- sh -c "curl -s '$URL' | tar -tvzf - | grep -c '^-'" || true)"
[ "$(CM files)" = "$COUNT" ] || fail "files is '$(CM files)', but the artifact holds $COUNT regular files."
echo "PASS: digest $CALC and $COUNT files match the served artifact."
