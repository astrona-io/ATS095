#!/usr/bin/env bash
# Confirms the Secret s3-credentials holds the keys accesskey and secretkey
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

KEYS="$(kubectl -n flux-system get secret s3-credentials -o jsonpath='{.data}' 2>/dev/null)"
[ -n "$KEYS" ] || fail "the Secret s3-credentials does not exist in flux-system."
for key in '"accesskey"' '"secretkey"'; do
  printf '%s' "$KEYS" | grep -q "$key" || fail "the Secret s3-credentials has no $key key."
done
[ "$(field bucket podinfo .spec.secretRef.name)" = "s3-credentials" ] || fail "the Bucket podinfo must reference the Secret s3-credentials."
echo "PASS: the Secret s3-credentials holds accesskey and secretkey."
