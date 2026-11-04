#!/usr/bin/env bash
# Confirms the registry holds podinfo-manifests:1.2.0 with the Git source and the commit of main as annotations, and still holds 1.0.0 and 1.1.0
set -uo pipefail
fail() { echo "FAIL: $*"; exit 1; }
REG="http://registry.registry.svc.cluster.local:5001/v2/podinfo-manifests"
tester() { kubectl -n gitea exec deploy/tester -- "$@"; }

TAGS="$(tester curl -fsS "$REG/tags/list" 2>/dev/null)"
[ -n "$TAGS" ] || fail "could not read the tags of podinfo-manifests from the registry."
for t in 1.0.0 1.1.0 1.2.0; do
  case "$TAGS" in *"\"$t\""*) ;; *) fail "the registry has no podinfo-manifests:$t." ;; esac
done
MANIFEST="$(tester curl -fsS -H 'Accept: application/vnd.oci.image.manifest.v1+json' "$REG/manifests/1.2.0" 2>/dev/null)"
COMMIT="$(tester curl -fsS -u gitops:gitops-password http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/branches/main 2>/dev/null | jq -r .commit.id)"
REVISION="$(printf '%s' "$MANIFEST" | jq -r '.annotations["org.opencontainers.image.revision"] // empty')"
SOURCE="$(printf '%s' "$MANIFEST" | jq -r '.annotations["org.opencontainers.image.source"] // empty')"
[ -n "$COMMIT" ] || fail "could not read the commit of main from Gitea."
[ "$REVISION" = "main@sha1:$COMMIT" ] || fail "the revision annotation of 1.2.0 is '$REVISION'; it must be main@sha1:$COMMIT."
case "$SOURCE" in *gitops/fleet*) ;; *) fail "the source annotation of 1.2.0 must name gitops/fleet (found: '$SOURCE')." ;; esac
echo "PASS: 1.2.0 carries the source and the commit of main."
