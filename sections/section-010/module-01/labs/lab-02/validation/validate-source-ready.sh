#!/usr/bin/env bash
# Confirms the GitRepository fleet is Ready on main with an artifact in storage and no fetch failure
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


REVISION="$(field gitrepository fleet .status.artifact.revision)"
[ "$(ready gitrepository fleet)" = "True" ] || fail "the GitRepository fleet is not Ready. Read its conditions with kubectl describe."
case "$REVISION" in main@sha1:*) ;; *) fail "the artifact revision is '$REVISION', expected main@sha1:<commit>." ;; esac
IN_STORAGE="$(field gitrepository fleet '.status.conditions[?(@.type=="ArtifactInStorage")].status')"
[ "$IN_STORAGE" = "True" ] || fail "the condition ArtifactInStorage is not True."
FETCH_FAILED="$(field gitrepository fleet '.status.conditions[?(@.type=="FetchFailed")].status')"
[ "$FETCH_FAILED" != "True" ] || fail "the condition FetchFailed is still True."
echo "PASS: fleet is Ready on $REVISION with its artifact in storage."
