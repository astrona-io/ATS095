#!/usr/bin/env bash
# Confirms regcred is a dockerconfigjson Secret for registry.localtest.me:5001 with the right user and the registry still requires authentication
set -uo pipefail
fail() { echo "FAIL: $*"; exit 1; }

TYPE="$(kubectl -n flux-system get secret regcred -o jsonpath='{.type}' 2>/dev/null)"
[ "$TYPE" = "kubernetes.io/dockerconfigjson" ] || fail "regcred must be of type kubernetes.io/dockerconfigjson (found: ${TYPE:-none})."
CONFIG="$(kubectl -n flux-system get secret regcred -o jsonpath='{.data.\.dockerconfigjson}' 2>/dev/null | base64 -d 2>/dev/null)"
case "$CONFIG" in *registry.localtest.me:5001*) ;; *) fail "regcred has no entry for registry.localtest.me:5001." ;; esac
CODE="$(kubectl -n gitea exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}' http://registry.localtest.me:5001/v2/ 2>/dev/null)"
[ "$CODE" = "401" ] || fail "the registry must still require authentication (anonymous status: $CODE)."
echo "PASS: regcred is a valid registry Secret and the registry still requires a sign-in."
