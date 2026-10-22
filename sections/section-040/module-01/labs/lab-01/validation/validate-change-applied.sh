#!/usr/bin/env bash
# Confirms the bucket holds the 3-replica change and Flux applied it from the Bucket revision
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
SOURCE="$(field bucket podinfo .status.artifact.revision)"
APPLIED="$(field kustomization podinfo .status.lastAppliedRevision)"
[ "$KIND" = "Bucket" ] || fail "the Flux Kustomization podinfo must use the Bucket podinfo (found kind: $KIND)."
[ "$(ready kustomization podinfo)" = "True" ] || fail "the Flux Kustomization podinfo is not Ready."
[ "$APPLIED" = "$SOURCE" ] || fail "podinfo applied '$APPLIED', but the Bucket is at '$SOURCE'."
IN_BUCKET="$(kubectl -n s3 exec deploy/s3-client -- aws s3 cp s3://podinfo/deployment.yaml - 2>/dev/null | awk '/replicas:/{print $2; exit}')"
[ "$IN_BUCKET" = "3" ] || fail "deployment.yaml in the bucket asks for ${IN_BUCKET:-?} replicas; upload the change to 3."
READY_REPLICAS="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
[ "$READY_REPLICAS" = "3" ] || fail "podinfo has ${READY_REPLICAS:-0} ready replicas; the bucket asks for 3."
echo "PASS: Flux applied the bucket's change; podinfo runs 3 ready replicas."
