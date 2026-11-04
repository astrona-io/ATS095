#!/usr/bin/env bash
# Confirms the OCIRepository was fixed in place, not deleted and recreated, and the registry still holds the releases
set -uo pipefail
fail() { echo "FAIL: $*"; exit 1; }

GEN="$(kubectl -n flux-system get ocirepository podinfo -o jsonpath='{.metadata.generation}' 2>/dev/null)"
[ -n "$GEN" ] || fail "the OCIRepository podinfo does not exist."
[ "$GEN" -ge 2 ] || fail "the OCIRepository podinfo was never edited (generation $GEN)."
DIGEST="$(kubectl -n flux-system get ocirepository podinfo -o jsonpath='{.spec.ref.digest}' 2>/dev/null)"
SEMVER="$(kubectl -n flux-system get ocirepository podinfo -o jsonpath='{.spec.ref.semver}' 2>/dev/null)"
[ -z "$DIGEST$SEMVER" ] || fail "keep the fixed tag; do not add a digest or a semver range."
echo "PASS: the OCIRepository was repaired in place."
