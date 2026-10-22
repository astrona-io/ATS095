#!/usr/bin/env bash
# Confirms the Bucket podinfo reads the bucket podinfo over HTTP every 30 minutes and is Ready
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

BUCKET="$(field bucket podinfo .spec.bucketName)"
ENDPOINT="$(field bucket podinfo .spec.endpoint)"
INSECURE="$(field bucket podinfo .spec.insecure)"
INTERVAL="$(field bucket podinfo .spec.interval)"
[ "$BUCKET" = "podinfo" ] || fail "the Bucket podinfo must read the bucket podinfo (found: ${BUCKET:-none})."
case "$ENDPOINT" in s3.s3.svc.cluster.local:9000|s3.s3:9000|s3.s3.svc:9000) ;; *) fail "the endpoint is '$ENDPOINT'; use s3.s3.svc.cluster.local:9000." ;; esac
[ "$INSECURE" = "true" ] || fail "the S3 server uses plain HTTP; the Bucket must set insecure: true."
case "$INTERVAL" in 30m|30m0s) ;; *) fail "the Bucket interval is '$INTERVAL'; it must stay 30m. Trigger a reconcile instead." ;; esac
[ "$(ready bucket podinfo)" = "True" ] || fail "the Bucket podinfo is not Ready."
echo "PASS: the Bucket podinfo is Ready at $(field bucket podinfo .status.artifact.revision)."
