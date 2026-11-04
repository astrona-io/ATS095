#!/usr/bin/env bash
# Confirms the flag is still set and the ServiceAccount team-a cannot create namespaces or read Secrets of flux-system
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

ARGS="$(kubectl -n flux-system get deployment kustomize-controller -o json | jq -c '.spec.template.spec.containers[0].args')"
echo "$ARGS" | jq -e 'any(.[]; . == "--no-cross-namespace-refs=true")' >/dev/null || fail "--no-cross-namespace-refs=true was removed from kustomize-controller."
SA="system:serviceaccount:team-a:team-a"
[ "$(kubectl auth can-i create namespaces --as="$SA")" = "no" ] || fail "the ServiceAccount team-a can create namespaces; do not widen its rights."
[ "$(kubectl auth can-i get secrets -n flux-system --as="$SA")" = "no" ] || fail "the ServiceAccount team-a can read Secrets in flux-system."
[ "$(kubectl auth can-i create configmaps -n team-a --as="$SA")" = "yes" ] || fail "the ServiceAccount team-a lost its rights in team-a."
echo "PASS: the flag is on and team-a is confined to its namespace."
