#!/usr/bin/env bash
# Confirms the Bucket podinfo reads the bucket podinfo over HTTP and is Ready
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

[ "$(field bucket podinfo .spec.bucketName)" = "podinfo" ] || fail "the Bucket must read the bucket podinfo."
[ "$(field bucket podinfo .spec.insecure)" = "true" ] || fail "the S3 server uses plain HTTP; the Bucket must set insecure: true."
[ "$(ready bucket podinfo)" = "True" ] || fail "the Bucket podinfo is not Ready."
echo "PASS: the Bucket podinfo is Ready at $(field bucket podinfo .status.artifact.revision)."
