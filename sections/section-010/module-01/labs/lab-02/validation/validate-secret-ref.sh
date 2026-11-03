#!/usr/bin/env bash
# Confirms fleet uses the existing Secret fleet-auth and that the Secret still holds basic authentication keys
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


SECRET="$(field gitrepository fleet .spec.secretRef.name)"
[ "$SECRET" = "fleet-auth" ] || fail "fleet must reference the Secret fleet-auth (found: ${SECRET:-none})."
KEYS="$(kubectl -n flux-system get secret fleet-auth -o jsonpath='{.data}' 2>/dev/null | tr -d "{}\"" | tr "," "\n" | cut -d: -f1 | sort | tr "\n" " ")"
case "$KEYS" in *password*username*) ;; *) fail "the Secret fleet-auth must keep the keys username and password (found: $KEYS)." ;; esac
[ -z "$(kubectl -n flux-system get secret fleet-credentials -o name 2>/dev/null)" ] || \
  fail "do not create a Secret named fleet-credentials; fix the reference in the GitRepository instead."
echo "PASS: fleet uses fleet-auth, which still holds username and password."
