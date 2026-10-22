#!/usr/bin/env bash
# Confirms the OCIRepository podinfo follows a semver range, is not pinned to a digest, and is Ready on 1.3.0
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

SEMVER="$(field ocirepository podinfo .spec.ref.semver)"
DIGEST="$(field ocirepository podinfo .spec.ref.digest)"
REVISION="$(field ocirepository podinfo .status.artifact.revision)"
[ -n "$SEMVER" ] || fail "the OCIRepository podinfo must follow a semver range."
[ -z "$DIGEST" ] || fail "the OCIRepository podinfo is pinned to a digest, which overrides the range."
[ "$(ready ocirepository podinfo)" = "True" ] || fail "the OCIRepository podinfo is not Ready."
case "$REVISION" in 1.3.0@sha256:*) ;; *) fail "podinfo is at '$REVISION'; the newest 1.x release must be 1.3.0." ;; esac
echo "PASS: the OCIRepository podinfo follows '$SEMVER' and is at $REVISION."
