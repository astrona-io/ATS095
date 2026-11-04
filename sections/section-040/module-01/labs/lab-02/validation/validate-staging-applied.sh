#!/usr/bin/env bash
# Confirms the Flux Kustomization releases applied the Bucket revision and podinfo-staging runs 2 ready replicas
set -uo pipefail
field() { kubectl -n flux-system get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null; }
fail() { echo "FAIL: $*"; exit 1; }

SOURCE="$(field bucket releases .status.artifact.revision)"
APPLIED="$(field kustomization releases .status.lastAppliedRevision)"
[ "$(field kustomization releases .spec.sourceRef.kind)" = "Bucket" ] || fail "the Kustomization releases must read the Bucket releases."
[ "$(field kustomization releases '.status.conditions[?(@.type=="Ready")].status')" = "True" ] || fail "the Flux Kustomization releases is not Ready."
[ -n "$SOURCE" ] && [ "$APPLIED" = "$SOURCE" ] || fail "releases applied '$APPLIED', but the Bucket is at '$SOURCE'."
READY="$(kubectl -n podinfo-staging get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
[ "$READY" = "2" ] || fail "podinfo in podinfo-staging has ${READY:-0} ready replicas; staging/ asks for 2."
echo "PASS: staging is applied from $APPLIED with 2 ready replicas."
