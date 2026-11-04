#!/usr/bin/env bash
# Confirms the bucket holds the 3-replica change, a reconcile was handled and Flux applied the Bucket revision
set -uo pipefail
field() { kubectl -n flux-system get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null; }
fail() { echo "FAIL: $*"; exit 1; }

IN_BUCKET="$(kubectl -n s3 exec deploy/s3-client -- aws s3 cp s3://podinfo/deployment.yaml - 2>/dev/null | awk '/replicas:/{print $2; exit}')"
[ "$IN_BUCKET" = "3" ] || fail "deployment.yaml in the bucket asks for ${IN_BUCKET:-?} replicas; upload the change to 3."
REQUESTED="$(kubectl -n flux-system get bucket podinfo -o jsonpath='{.metadata.annotations.reconcile\.fluxcd\.io/requestedAt}' 2>/dev/null)"
HANDLED="$(field bucket podinfo .status.lastHandledReconcileAt)"
[ -n "$REQUESTED" ] || fail "the Bucket has no reconcile request; nobody called the webhook."
[ "$REQUESTED" = "$HANDLED" ] || fail "the reconcile request '$REQUESTED' was not handled yet ('$HANDLED')."
SOURCE="$(field bucket podinfo .status.artifact.revision)"
APPLIED="$(field kustomization podinfo .status.lastAppliedRevision)"
[ "$APPLIED" = "$SOURCE" ] || fail "podinfo applied '$APPLIED', but the Bucket is at '$SOURCE'."
READY="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
[ "$READY" = "3" ] || fail "podinfo has ${READY:-0} ready replicas; the bucket asks for 3."
echo "PASS: the change is applied; podinfo runs 3 ready replicas."
