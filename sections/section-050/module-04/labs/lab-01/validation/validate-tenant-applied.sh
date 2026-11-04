#!/usr/bin/env bash
# Confirms team-a-apps is Ready and the ConfigMap team-a-config exists in team-a
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

[ "$(ready kustomization team-a-apps team-a)" = "True" ] || fail "team-a-apps is not Ready: $(field kustomization team-a-apps '.status.conditions[?(@.type=="Ready")].message' team-a)"
G="$(field configmap team-a-config .data.greeting team-a)"
[ "$G" = "hello from team-a" ] || fail "the ConfigMap team-a-config is missing or wrong (greeting='$G')."
echo "PASS: team-a-apps is Ready and applied team-a-config."
