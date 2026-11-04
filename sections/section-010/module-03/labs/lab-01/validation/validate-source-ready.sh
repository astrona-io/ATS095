#!/usr/bin/env bash
# Confirms the GitRepository fleet is Ready, follows branch main and has no ref.name
set -uo pipefail
field() { kubectl -n flux-system get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null; }
fail() { echo "FAIL: $*"; exit 1; }

READY="$(field gitrepository fleet '.status.conditions[?(@.type=="Ready")].status')"
BRANCH="$(field gitrepository fleet .spec.ref.branch)"
NAME="$(field gitrepository fleet .spec.ref.name)"
REVISION="$(field gitrepository fleet .status.artifact.revision)"
[ "$READY" = "True" ] || fail "the GitRepository fleet is not Ready."
[ "$BRANCH" = "main" ] || fail "fleet must follow branch main (found: ${BRANCH:-none})."
[ -z "$NAME" ] || fail "spec.ref.name is still set ($NAME) and overrides the branch."
case "$REVISION" in
  main@*) ;;
  *) fail "the revision should start with main@ (found: $REVISION)." ;;
esac
echo "PASS: fleet is Ready on $REVISION."
