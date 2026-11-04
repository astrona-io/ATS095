#!/usr/bin/env bash
# Confirms team-a-apps uses a GitRepository in team-a and the ServiceAccount team-a, and that the source is Ready
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

NS="$(field kustomization team-a-apps .spec.sourceRef.namespace team-a)"
[ -z "$NS" ] || [ "$NS" = "team-a" ] || fail "sourceRef points at the namespace '$NS'; it must stay in team-a."
SRC="$(field kustomization team-a-apps .spec.sourceRef.name team-a)"
[ "$(ready gitrepository "$SRC" team-a)" = "True" ] || fail "the GitRepository '$SRC' in team-a is not Ready."
[ "$(field gitrepository "$SRC" .spec.secretRef.name team-a)" != "" ] || fail "the source in team-a has no secretRef; the repository is private."
SA="$(field kustomization team-a-apps .spec.serviceAccountName team-a)"
[ "$SA" = "team-a" ] || fail "serviceAccountName is '${SA:-unset}'; it must be team-a."
echo "PASS: team-a-apps follows $SRC in team-a as the ServiceAccount team-a."
