#!/usr/bin/env bash
# Confirms the Receiver is generic, Ready, has a token Secret with the key token and a webhookPath, and selects the Bucket podinfo
set -uo pipefail
field() { kubectl -n flux-system get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null; }
fail() { echo "FAIL: $*"; exit 1; }

R="$(kubectl -n flux-system get receivers.notification.toolkit.fluxcd.io -o name 2>/dev/null | head -1)"
[ -n "$R" ] || fail "no Receiver exists in flux-system."
NAME="${R#*/}"
[ "$(field receiver "$NAME" .spec.type)" = "generic" ] || fail "the Receiver must have type generic."
SECRET="$(field receiver "$NAME" .spec.secretRef.name)"
[ -n "$SECRET" ] || fail "the Receiver has no secretRef."
[ -n "$(kubectl -n flux-system get secret "$SECRET" -o jsonpath='{.data.token}' 2>/dev/null)" ] || fail "the Secret $SECRET has no key token."
KINDS="$(field receiver "$NAME" '.spec.resources[*].kind'):$(field receiver "$NAME" '.spec.resources[*].name')"
[ "$KINDS" = "Bucket:podinfo" ] || fail "the Receiver must select exactly the Bucket podinfo (found $KINDS)."
[ "$(field receiver "$NAME" '.status.conditions[?(@.type=="Ready")].status')" = "True" ] || fail "the Receiver is not Ready."
[ -n "$(field receiver "$NAME" .status.webhookPath)" ] || fail "the Receiver has no webhookPath yet."
echo "PASS: the Receiver $NAME is Ready and selects the Bucket podinfo."
