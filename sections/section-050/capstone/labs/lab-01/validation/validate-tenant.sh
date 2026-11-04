#!/usr/bin/env bash
# Confirms team-b-apps is Ready through a source in team-b as the ServiceAccount team-b, the flag is on and the account is confined
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

kubectl -n flux-system get deployment kustomize-controller -o json | jq -e '.spec.template.spec.containers[0].args | any(.[]; . == "--no-cross-namespace-refs=true")' >/dev/null || fail "--no-cross-namespace-refs=true was removed from kustomize-controller."
[ "$(ready kustomization team-b-apps team-b)" = "True" ] || fail "team-b-apps is not Ready."
NS="$(field kustomization team-b-apps .spec.sourceRef.namespace team-b)"
[ -z "$NS" ] || [ "$NS" = "team-b" ] || fail "team-b-apps still points at the namespace '$NS'."
[ "$(field kustomization team-b-apps .spec.serviceAccountName team-b)" = "team-b" ] || fail "team-b-apps must apply as the ServiceAccount team-b."
[ "$(field configmap team-b-config .data.greeting team-b)" = "hello from team-b" ] || fail "the ConfigMap team-b-config is missing."
[ "$(kubectl auth can-i create namespaces --as=system:serviceaccount:team-b:team-b)" = "no" ] || fail "team-b can create namespaces."
echo "PASS: team-b applies its own source as team-b and is confined."
