#!/usr/bin/env bash
# Confirms podinfo applies the new revision and runs 4 ready replicas
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

SOURCE="$(field gitrepository fleet .status.artifact.revision)"
APPLIED="$(field kustomization podinfo .status.lastAppliedRevision)"
[ "$(ready kustomization podinfo)" = "True" ] || fail "the Flux Kustomization podinfo is not Ready."
[ "$APPLIED" = "$SOURCE" ] || fail "podinfo applied '$APPLIED', but the source is at '$SOURCE'."
R="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
[ "$R" = "4" ] || fail "the Deployment podinfo has ${R:-0} ready replicas; the commit should ask for 4."
echo "PASS: podinfo applies $APPLIED and runs 4 ready replicas."
