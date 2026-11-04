#!/usr/bin/env bash
# Confirms the OCIRepository podinfo uses the Secret regcred, keeps tag 1.1.0 and is Ready
set -uo pipefail
field() { kubectl -n flux-system get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null; }
fail() { echo "FAIL: $*"; exit 1; }

SECRET="$(field ocirepository podinfo .spec.secretRef.name)"
TAG="$(field ocirepository podinfo .spec.ref.tag)"
READY="$(field ocirepository podinfo '.status.conditions[?(@.type=="Ready")].status')"
REVISION="$(field ocirepository podinfo .status.artifact.revision)"
[ "$SECRET" = "regcred" ] || fail "spec.secretRef.name must be regcred (found: ${SECRET:-none})."
[ "$TAG" = "1.1.0" ] || fail "ref.tag must stay 1.1.0 (found: ${TAG:-none})."
[ "$READY" = "True" ] || fail "the OCIRepository podinfo is not Ready."
case "$REVISION" in 1.1.0@sha256:*) ;; *) fail "the revision should start with 1.1.0@sha256: (found: $REVISION)." ;; esac
echo "PASS: podinfo is Ready at $REVISION with the Secret $SECRET."
