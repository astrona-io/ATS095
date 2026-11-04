#!/usr/bin/env bash
# Confirms the OCIRepository podinfo uses the right url, insecure and tag 1.1.0 and is Ready
set -uo pipefail
field() { kubectl -n flux-system get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null; }
fail() { echo "FAIL: $*"; exit 1; }

URL="$(field ocirepository podinfo .spec.url)"
INSECURE="$(field ocirepository podinfo .spec.insecure)"
TAG="$(field ocirepository podinfo .spec.ref.tag)"
READY="$(field ocirepository podinfo '.status.conditions[?(@.type=="Ready")].status')"
REVISION="$(field ocirepository podinfo .status.artifact.revision)"
[ "$URL" = "oci://registry.localtest.me:5001/podinfo-manifests" ] || fail "the url must be oci://registry.localtest.me:5001/podinfo-manifests (found: $URL)."
[ "$INSECURE" = "true" ] || fail "the registry uses plain HTTP, so spec.insecure must be true."
[ "$TAG" = "1.1.0" ] || fail "ref.tag must be 1.1.0 (found: ${TAG:-none})."
[ "$READY" = "True" ] || fail "the OCIRepository podinfo is not Ready."
case "$REVISION" in 1.1.0@sha256:*) ;; *) fail "the revision should start with 1.1.0@sha256: (found: $REVISION)." ;; esac
echo "PASS: podinfo is Ready at $REVISION."
