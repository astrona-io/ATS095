#!/usr/bin/env bash
# Confirms the new source-controller pod is rolled out and available, and that fleet and podinfo are Ready
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

G="$(field deployment source-controller .metadata.generation)"
O="$(field deployment source-controller .status.observedGeneration)"
[ "$G" = "$O" ] || fail "the Deployment has not observed generation $G yet."
D="$(field deployment source-controller .spec.replicas)"
U="$(field deployment source-controller .status.updatedReplicas)"
A="$(field deployment source-controller .status.availableReplicas)"
[ "$U" = "$D" ] && [ "$A" = "$D" ] || fail "source-controller is not fully rolled out (desired $D, updated ${U:-0}, available ${A:-0})."
[ "$(ready gitrepository fleet)" = "True" ] || fail "fleet is not Ready after the restart."
[ "$(ready kustomization podinfo)" = "True" ] || fail "the Flux Kustomization podinfo is not Ready."
echo "PASS: source-controller is rolled out and fleet and podinfo are Ready."
