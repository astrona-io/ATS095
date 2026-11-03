#!/usr/bin/env bash
# Confirms fleet keeps its address, follows the branch main, is not suspended, and the repository has no release branch
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
BRANCH="$(field gitrepository fleet .spec.ref.branch)"
SUSPEND="$(field gitrepository fleet .spec.suspend)"
[ "$URL" = "http://gitea.localtest.me:3000/gitops/fleet.git" ] || fail "do not change the address of fleet (found: $URL)."
[ "$BRANCH" = "main" ] || fail "fleet must follow the branch main (found: ${BRANCH:-none})."
[ "$SUSPEND" != "true" ] || fail "fleet is suspended; resume it."
BRANCHES="$(kubectl -n gitea exec deploy/tester -- \
  curl -fsS -u gitops:gitops-password http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/branches 2>/dev/null)"
[ -n "$BRANCHES" ] || fail "could not read the branches of gitops/fleet."
case "$BRANCHES" in *'"name":"release"'*) fail "do not create a release branch in gitops/fleet; fix the GitRepository instead." ;; esac
echo "PASS: fleet keeps its address, follows main and is not suspended, and gitops/fleet has no release branch."
