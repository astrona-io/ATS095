#!/usr/bin/env bash
# Confirms the GitRepository fleet uses the SSH address with port 2222 and the Secret fleet-ssh and is Ready on main
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

URL="$(field gitrepository fleet .spec.url)"
SECRET="$(field gitrepository fleet .spec.secretRef.name)"
REVISION="$(field gitrepository fleet .status.artifact.revision)"
[ "$URL" = "ssh://git@gitea.localtest.me:2222/gitops/fleet.git" ] || \
  fail "fleet must use ssh://git@gitea.localtest.me:2222/gitops/fleet.git (found: $URL)."
[ "$SECRET" = "fleet-ssh" ] || fail "fleet must keep the Secret fleet-ssh (found: ${SECRET:-none})."
[ "$(ready gitrepository fleet)" = "True" ] || fail "the GitRepository fleet is not Ready."
case "$REVISION" in main@sha1:*) ;; *) fail "the artifact revision is '$REVISION', expected main@sha1:<commit>." ;; esac
echo "PASS: fleet reads gitops/fleet over SSH on port 2222 and is Ready at $REVISION."
