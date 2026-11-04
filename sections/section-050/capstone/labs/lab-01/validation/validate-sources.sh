#!/usr/bin/env bash
# Confirms fleet follows main and platform is resumed, both Ready, and that podinfo and platform-settings apply their revisions
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

[ "$(field gitrepository fleet .spec.ref.branch)" = "main" ] || fail "fleet does not follow main."
[ "$(field gitrepository platform .spec.suspend)" != "true" ] || fail "platform is still suspended."
for s in fleet platform; do
  [ "$(ready gitrepository $s)" = "True" ] || fail "$s is not Ready: $(field gitrepository $s '.status.conditions[?(@.type=="Ready")].message')"
done
for pair in podinfo:fleet platform-settings:platform; do
  k="${pair%%:*}"; s="${pair##*:}"
  [ "$(ready kustomization $k)" = "True" ] || fail "the Flux Kustomization $k is not Ready."
  [ "$(field kustomization $k .status.lastAppliedRevision)" = "$(field gitrepository $s .status.artifact.revision)" ] || fail "$k does not apply the revision of $s."
done
echo "PASS: fleet and platform are Ready and their Kustomizations apply the current revisions."
