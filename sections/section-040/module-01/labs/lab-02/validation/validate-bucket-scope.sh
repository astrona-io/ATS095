#!/usr/bin/env bash
# Confirms the Bucket releases reads only the prefix staging/, ignores the draft folder, keeps its 30m interval and is Ready
set -uo pipefail
field() { kubectl -n flux-system get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null; }
fail() { echo "FAIL: $*"; exit 1; }

PREFIX="$(field bucket releases .spec.prefix)"
IGNORE="$(field bucket releases .spec.ignore)"
INTERVAL="$(field bucket releases .spec.interval)"
[ "$PREFIX" = "staging/" ] || fail "spec.prefix is '${PREFIX:-empty}'; the Bucket must read only staging/."
case "$IGNORE" in *draft*) ;; *) fail "spec.ignore does not exclude the draft folder (found: '${IGNORE:-empty}')." ;; esac
case "$INTERVAL" in 30m|30m0s) ;; *) fail "the Bucket interval is '$INTERVAL'; it must stay 30m." ;; esac
[ "$(field bucket releases '.status.conditions[?(@.type=="Ready")].status')" = "True" ] || fail "the Bucket releases is not Ready."
echo "PASS: the Bucket reads staging/ only and ignores the draft."
