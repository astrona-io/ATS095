#!/usr/bin/env bash
# Confirms fleet follows a semver range and is Ready on v1.2.0, without a pinned tag, name or commit
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

SEMVER="$(field gitrepository fleet .spec.ref.semver)"
PINNED="$(field gitrepository fleet .spec.ref.tag)$(field gitrepository fleet .spec.ref.name)$(field gitrepository fleet .spec.ref.commit)"
REVISION="$(field gitrepository fleet .status.artifact.revision)"
[ -n "$SEMVER" ] || fail "fleet must follow a semver range."
[ -z "$PINNED" ] || fail "fleet pins a tag, a name or a commit. Use a semver range only."
[ "$(ready gitrepository fleet)" = "True" ] || fail "the GitRepository fleet is not Ready."
case "$REVISION" in v1.2.0@sha1:*) ;; *) fail "fleet is at '$REVISION'; the newest 1.x release is v1.2.0." ;; esac
echo "PASS: fleet follows '$SEMVER' and is at $REVISION."
