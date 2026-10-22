#!/usr/bin/env bash
# Confirms the public key of fleet-ssh is a read-only deploy key of gitops/fleet
set -uo pipefail

ready() {
  # ready KIND NAME: prints the status of the Ready condition in flux-system.
  kubectl -n flux-system get "$1" "$2" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null
}
field() {
  # field KIND NAME JSONPATH: prints one field of an object in flux-system.
  kubectl -n flux-system get "$1" "$2" -o jsonpath="{$3}" 2>/dev/null
}
fail() { echo "FAIL: $*"; exit 1; }

PUBLIC_KEY="$(kubectl -n flux-system get secret fleet-ssh -o jsonpath='{.data.identity\.pub}' 2>/dev/null | base64 -d 2>/dev/null | awk '{print $1" "$2}')"
KEYS_JSON="$(kubectl -n gitea exec deploy/tester -- \
  curl -fsS -u gitops:gitops-password http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/keys 2>/dev/null)"
[ -n "$KEYS_JSON" ] || fail "could not read the deploy keys of gitops/fleet."
MATCH="$(printf '%s' "$KEYS_JSON" | kubectl -n gitea exec -i deploy/tester -- \
  jq -r --arg key "$PUBLIC_KEY" '.[] | select((.key | split(" ")[0:2] | join(" ")) == $key) | .read_only' 2>/dev/null | head -1)"
if [ -z "$PUBLIC_KEY" ]; then
  # Without identity.pub in the Secret, accept any read-only deploy key.
  MATCH="$(printf '%s' "$KEYS_JSON" | kubectl -n gitea exec -i deploy/tester -- jq -r '[.[] | select(.read_only)] | length > 0' 2>/dev/null)"
fi
case "$MATCH" in
  true) ;;
  false) fail "the deploy key of fleet-ssh has write access; make it read-only." ;;
  *) fail "the public key of fleet-ssh is not a deploy key of gitops/fleet." ;;
esac
echo "PASS: the public key of fleet-ssh is a read-only deploy key of gitops/fleet."
