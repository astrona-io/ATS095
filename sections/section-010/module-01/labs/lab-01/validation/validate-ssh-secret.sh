#!/usr/bin/env bash
# Confirms fleet-ssh holds an SSH identity and known_hosts, and the password Secret fleet-auth is gone
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

KEYS="$(kubectl -n flux-system get secret fleet-ssh -o jsonpath='{.data}' 2>/dev/null)"
[ -n "$KEYS" ] || fail "the Secret fleet-ssh does not exist in flux-system."
for key in '"identity"' '"known_hosts"'; do
  printf '%s' "$KEYS" | grep -q "$key" || fail "the Secret fleet-ssh has no $key key."
done
printf '%s' "$KEYS" | grep -q '"password"' && fail "the Secret fleet-ssh still holds a password; it must hold only the SSH key."
if kubectl -n flux-system get secret fleet-auth >/dev/null 2>&1; then
  fail "the password Secret fleet-auth still exists. Delete it once Flux reads over SSH."
fi
echo "PASS: fleet-ssh holds an SSH identity and known_hosts, and fleet-auth is gone."
