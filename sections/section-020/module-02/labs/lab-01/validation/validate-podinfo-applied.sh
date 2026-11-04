#!/usr/bin/env bash
# Confirms the Flux Kustomization podinfo applies the OCI revision and podinfo runs the 3 replicas of release 1.1.0
set -uo pipefail
field() { kubectl -n flux-system get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null; }
fail() { echo "FAIL: $*"; exit 1; }

SOURCE="$(field ocirepository podinfo .status.artifact.revision)"
APPLIED="$(field kustomization podinfo .status.lastAppliedRevision)"
READY="$(field kustomization podinfo '.status.conditions[?(@.type=="Ready")].status')"
[ -n "$SOURCE" ] || fail "the OCIRepository has no artifact yet."
[ "$READY" = "True" ] || fail "the Flux Kustomization podinfo is not Ready."
[ "$APPLIED" = "$SOURCE" ] || fail "podinfo applied '$APPLIED', but the source is at '$SOURCE'."
REPLICAS="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
[ "$REPLICAS" = "3" ] || fail "the Deployment podinfo has ${REPLICAS:-0} ready replicas; release 1.1.0 asks for 3."
echo "PASS: podinfo applies $APPLIED and runs 3 ready replicas."
