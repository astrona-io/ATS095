#!/usr/bin/env bash
# Confirms the registry holds podinfo-manifests:1.3.0 and still holds 2.0.0
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

TAGS="$(kubectl -n gitea exec deploy/tester -- \
  curl -fsS http://registry.registry.svc.cluster.local:5001/v2/podinfo-manifests/tags/list 2>/dev/null)"
[ -n "$TAGS" ] || fail "could not read the tags of podinfo-manifests from the registry."
printf '%s' "$TAGS" | grep -q '"1.3.0"' || fail "the registry has no podinfo-manifests:1.3.0. Push it with flux push artifact."
printf '%s' "$TAGS" | grep -q '"2.0.0"' || fail "podinfo-manifests:2.0.0 is gone. Leave the other releases in place."
echo "PASS: the registry holds podinfo-manifests:1.3.0."
