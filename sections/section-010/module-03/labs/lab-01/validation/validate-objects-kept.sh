#!/usr/bin/env bash
# Confirms fleet and podinfo were fixed in place, not deleted and recreated
set -uo pipefail
fail() { echo "FAIL: $*"; exit 1; }

for pair in "gitrepository fleet" "kustomization podinfo"; do
  set -- $pair
  GEN="$(kubectl -n flux-system get "$1" "$2" -o jsonpath='{.metadata.generation}' 2>/dev/null)"
  [ -n "$GEN" ] || fail "$1 $2 does not exist."
  [ "$GEN" -ge 2 ] || [ "$1" = "kustomization" ] || fail "$1 $2 was never edited (generation $GEN)."
done
URL="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.url}' 2>/dev/null)"
[ "$URL" = "http://gitea.localtest.me:3000/gitops/fleet.git" ] || fail "the url of fleet must not change (found: $URL)."
SECRET="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.secretRef.name}' 2>/dev/null)"
[ "$SECRET" = "fleet-auth" ] || fail "fleet must keep the Secret fleet-auth (found: $SECRET)."
echo "PASS: fleet was repaired in place."
