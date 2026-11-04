#!/usr/bin/env bash
# Confirms the OCIRepository podinfo is pinned to the digest of 1.2.0, has no tag, and is Ready
set -uo pipefail
field() { kubectl -n flux-system get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null; }
fail() { echo "FAIL: $*"; exit 1; }

REG="http://registry.registry.svc.cluster.local:5001/v2/podinfo-manifests"
DIGEST="$(kubectl -n gitea exec deploy/tester -- curl -fsSI -H 'Accept: application/vnd.oci.image.manifest.v1+json' "$REG/manifests/1.2.0" 2>/dev/null \
  | tr -d '\r' | awk 'tolower($1)=="docker-content-digest:" {print $2}')"
PINNED="$(field ocirepository podinfo .spec.ref.digest)"
TAG="$(field ocirepository podinfo .spec.ref.tag)"
READY="$(field ocirepository podinfo '.status.conditions[?(@.type=="Ready")].status')"
REVISION="$(field ocirepository podinfo .status.artifact.revision)"
[ -n "$DIGEST" ] || fail "the registry does not hold podinfo-manifests:1.2.0."
[ "$PINNED" = "$DIGEST" ] || fail "ref.digest is '${PINNED:-empty}'; it must be the digest of 1.2.0 ($DIGEST)."
[ -z "$TAG" ] || fail "ref.tag is still set ($TAG)."
[ "$READY" = "True" ] || fail "the OCIRepository podinfo is not Ready."
case "$REVISION" in *"$DIGEST"*) ;; *) fail "the revision '$REVISION' does not hold the pinned digest." ;; esac
echo "PASS: podinfo is pinned to $DIGEST."
