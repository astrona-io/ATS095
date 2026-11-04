#!/usr/bin/env bash
# Confirms the ConfigMap artifact-proof names the revision fleet serves now and not the initial one
set -uo pipefail

ready() {
  # ready KIND NAME [NAMESPACE]: prints the status of the Ready condition.
  kubectl -n "${3:-flux-system}" get "$1" "$2" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null
}
field() {
  # field KIND NAME JSONPATH [NAMESPACE]: prints one field of an object.
  kubectl -n "${4:-flux-system}" get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null
}
fail() { echo "FAIL: $*"; exit 1; }

CM() { kubectl -n flux-system get configmap artifact-proof -o "jsonpath={.data.$1}" 2>/dev/null; }
[ -n "$(CM revision)" ] || fail "the ConfigMap artifact-proof in flux-system has no key 'revision'."
[ -n "$(CM digest)" ] || fail "the ConfigMap artifact-proof has no key 'digest'."
[ -n "$(CM files)" ] || fail "the ConfigMap artifact-proof has no key 'files'."
SOURCE="$(field gitrepository fleet .status.artifact.revision)"
INITIAL="$(field configmap lab-initial .data.revision default)"
[ "$SOURCE" != "$INITIAL" ] || fail "fleet still serves the initial revision; push a commit to Git first."
[ "$(CM revision)" = "$SOURCE" ] || fail "revision '$(CM revision)' is not the revision fleet serves now ('$SOURCE')."
echo "PASS: artifact-proof names the current revision $SOURCE."
