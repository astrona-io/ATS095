#!/usr/bin/env bash
# Confirms podinfo runs the v1.2.0 release: podinfo 6.15.0 with 2 ready replicas
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

SOURCE="$(field gitrepository fleet .status.artifact.revision)"
APPLIED="$(field kustomization podinfo .status.lastAppliedRevision)"
[ "$(ready kustomization podinfo)" = "True" ] || fail "the Flux Kustomization podinfo is not Ready."
[ "$APPLIED" = "$SOURCE" ] || fail "podinfo applied '$APPLIED', but the source is at '$SOURCE'."
IMAGE="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
[ "$IMAGE" = "ghcr.io/stefanprodan/podinfo:6.15.0" ] || fail "podinfo runs '$IMAGE'; release v1.2.0 uses ghcr.io/stefanprodan/podinfo:6.15.0."
READY_REPLICAS="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
[ "$READY_REPLICAS" = "2" ] || fail "podinfo has ${READY_REPLICAS:-0} ready replicas; release v1.2.0 asks for 2."
echo "PASS: podinfo runs release v1.2.0 with 2 ready replicas."
