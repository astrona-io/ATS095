#!/usr/bin/env bash
# Confirms fleet-tags is resumed, Ready and serves the revision of tag v1.1.0
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

S="$(field gitrepository fleet-tags .spec.suspend)"
[ "$S" != "true" ] || fail "fleet-tags is still suspended."
[ "$(field gitrepository fleet-tags .spec.ref.tag)" = "v1.1.0" ] || fail "fleet-tags must keep following the tag v1.1.0."
[ "$(ready gitrepository fleet-tags)" = "True" ] || fail "fleet-tags is not Ready."
REV="$(field gitrepository fleet-tags .status.artifact.revision)"
case "$REV" in v1.1.0@sha1:*) ;; *) fail "fleet-tags serves '$REV', not v1.1.0@sha1:...";; esac
echo "PASS: fleet-tags is resumed and serves $REV."
