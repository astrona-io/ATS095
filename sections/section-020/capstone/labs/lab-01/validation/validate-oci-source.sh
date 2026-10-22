#!/usr/bin/env bash
# Confirms the OCIRepository podinfo has a URL without a tag, allows HTTP, follows a semver range and is Ready on 1.1.0
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

URL="$(field ocirepository podinfo .spec.url)"
INSECURE="$(field ocirepository podinfo .spec.insecure)"
SEMVER="$(field ocirepository podinfo .spec.ref.semver)"
DIGEST="$(field ocirepository podinfo .spec.ref.digest)"
REVISION="$(field ocirepository podinfo .status.artifact.revision)"
[ "$URL" = "oci://registry.localtest.me:5001/podinfo-manifests" ] || fail "the URL must be oci://registry.localtest.me:5001/podinfo-manifests, without a tag (found: $URL)."
[ "$INSECURE" = "true" ] || fail "the registry uses plain HTTP; the OCIRepository must allow it."
[ -n "$SEMVER" ] || fail "the OCIRepository must follow a semver range."
[ -z "$DIGEST" ] || fail "the OCIRepository is pinned to a digest, which overrides the range."
[ "$(ready ocirepository podinfo)" = "True" ] || fail "the OCIRepository podinfo is not Ready."
case "$REVISION" in 1.1.0@sha256:*) ;; *) fail "podinfo is at '$REVISION'; the newest 1.x release is 1.1.0." ;; esac
echo "PASS: the OCIRepository podinfo is Ready at $REVISION."
