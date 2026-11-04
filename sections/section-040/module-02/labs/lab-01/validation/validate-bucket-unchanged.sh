#!/usr/bin/env bash
# Confirms the Bucket podinfo still checks every 30 minutes and is Ready
set -uo pipefail
field() { kubectl -n flux-system get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null; }
INTERVAL="$(field bucket podinfo .spec.interval)"
case "$INTERVAL" in 30m|30m0s) ;; *) echo "FAIL: the Bucket interval is '$INTERVAL'; it must stay 30m."; exit 1 ;; esac
[ "$(field bucket podinfo '.status.conditions[?(@.type=="Ready")].status')" = "True" ] || { echo "FAIL: the Bucket podinfo is not Ready."; exit 1; }
echo "PASS: the Bucket keeps its 30m interval."
