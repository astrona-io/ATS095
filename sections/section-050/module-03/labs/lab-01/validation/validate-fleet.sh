#!/usr/bin/env bash
# Confirms fleet follows branch main, is Ready, and podinfo applies its revision
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

[ "$(field gitrepository fleet .spec.ref.branch)" = "main" ] || fail "fleet does not follow branch main (ref: $(field gitrepository fleet .spec.ref))."
[ "$(ready gitrepository fleet)" = "True" ] || fail "fleet is not Ready: $(field gitrepository fleet '.status.conditions[?(@.type=="Ready")].message')"
SOURCE="$(field gitrepository fleet .status.artifact.revision)"
APPLIED="$(field kustomization podinfo .status.lastAppliedRevision)"
[ "$(ready kustomization podinfo)" = "True" ] || fail "the Flux Kustomization podinfo is not Ready."
[ "$APPLIED" = "$SOURCE" ] || fail "podinfo applied '$APPLIED', but fleet is at '$SOURCE'."
echo "PASS: fleet follows main and podinfo applies $APPLIED."
