#!/usr/bin/env bash
# Confirms the Flux Kustomization podinfo reads the OCIRepository, is Ready, and podinfo runs the 3 replicas of release 1.1.0
set -uo pipefail

ready() {
  # ready KIND NAME: prints the status of the Ready condition in flux-system.
  kubectl -n flux-system get "$1" "$2" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null
}
field() {
  # field KIND NAME JSONPATH: prints one field of an object in flux-system.
  kubectl -n flux-system get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null
}
fail() { echo "FAIL: $*"; exit 1; }

KIND="$(field kustomization podinfo .spec.sourceRef.kind)"
SOURCE="$(field ocirepository podinfo .status.artifact.revision)"
APPLIED="$(field kustomization podinfo .status.lastAppliedRevision)"
[ "$KIND" = "OCIRepository" ] || fail "the Flux Kustomization podinfo still names a $KIND."
[ "$(ready kustomization podinfo)" = "True" ] || fail "the Flux Kustomization podinfo is not Ready."
[ "$APPLIED" = "$SOURCE" ] || fail "podinfo applied '$APPLIED', but the source is at '$SOURCE'."
READY_REPLICAS="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
[ "$READY_REPLICAS" = "3" ] || fail "podinfo has ${READY_REPLICAS:-0} ready replicas; release 1.1.0 asks for 3."
echo "PASS: podinfo applies $APPLIED and runs 3 ready replicas."
