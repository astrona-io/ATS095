#!/usr/bin/env bash
# Confirms platform-auth holds the correct password, platform is Ready and platform-settings applies its revision
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

PASS="$(kubectl -n flux-system get secret platform-auth -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)"
USER="$(kubectl -n flux-system get secret platform-auth -o jsonpath='{.data.username}' 2>/dev/null | base64 -d)"
[ "$USER" = "gitops" ] || fail "platform-auth has username '$USER'."
[ "$PASS" = "gitops-password" ] || fail "platform-auth holds the wrong password."
[ "$(field gitrepository platform .spec.secretRef.name)" = "platform-auth" ] || fail "platform must keep using the Secret platform-auth."
[ "$(ready gitrepository platform)" = "True" ] || fail "platform is not Ready: $(field gitrepository platform '.status.conditions[?(@.type=="Ready")].message')"
SOURCE="$(field gitrepository platform .status.artifact.revision)"
APPLIED="$(field kustomization platform-settings .status.lastAppliedRevision)"
[ "$(ready kustomization platform-settings)" = "True" ] || fail "platform-settings is not Ready."
[ "$APPLIED" = "$SOURCE" ] || fail "platform-settings applied '$APPLIED', but platform is at '$SOURCE'."
kubectl -n default get configmap podinfo-settings >/dev/null 2>&1 || fail "the ConfigMap podinfo-settings was not applied."
echo "PASS: platform fetches with the right password and platform-settings applies $APPLIED."
