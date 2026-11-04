#!/usr/bin/env bash
# Confirms the HelmRepository was not changed: it still points at the HTTP repository and is Ready
set -uo pipefail
fail() { echo "FAIL: $*"; exit 1; }

URL="$(kubectl -n flux-system get helmrepository podinfo -o jsonpath='{.spec.url}' 2>/dev/null)"
TYPE="$(kubectl -n flux-system get helmrepository podinfo -o jsonpath='{.spec.type}' 2>/dev/null)"
READY="$(kubectl -n flux-system get helmrepository podinfo -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
[ "$URL" = "https://stefanprodan.github.io/podinfo" ] || fail "the HelmRepository podinfo must keep its address (found: $URL). The fault is in the HelmChart."
case "$TYPE" in ""|default) ;; *) fail "the HelmRepository type must stay default (found: $TYPE)." ;; esac
[ "$READY" = "True" ] || fail "the HelmRepository podinfo is not Ready."
echo "PASS: the HelmRepository podinfo is unchanged and Ready."
