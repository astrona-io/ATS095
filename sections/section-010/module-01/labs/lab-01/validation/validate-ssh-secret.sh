#!/usr/bin/env bash
# Confirms fleet-ssh holds an SSH identity and known_hosts, and the password Secret fleet-auth is gone
set -uo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

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
