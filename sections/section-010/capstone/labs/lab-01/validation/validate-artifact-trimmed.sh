#!/usr/bin/env bash
# Confirms the artifact of fleet holds apps/podinfo and no docs folder
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

URL="$(field gitrepository fleet .status.artifact.url)"
[ -n "$URL" ] || fail "fleet has no artifact."
# Network policies allow traffic to source-controller only from flux-system,
# so the artifact is read by a short-lived pod there.
FILES="$(kubectl -n flux-system run "grader-artifact-$$" --rm -i --restart=Never --quiet \
  --image=nicolaka/netshoot:v0.13 -- sh -c "curl -fsS '$URL' | tar -tzf -" 2>/dev/null)"
[ -n "$FILES" ] || fail "could not list the files in the artifact of fleet."
printf '%s\n' "$FILES" | grep -q 'apps/podinfo/deployment.yaml' || fail "the artifact no longer holds apps/podinfo."
printf '%s\n' "$FILES" | grep -q 'docs/' && fail "the artifact still holds the docs folder."
echo "PASS: the artifact holds apps/podinfo and no docs folder."
