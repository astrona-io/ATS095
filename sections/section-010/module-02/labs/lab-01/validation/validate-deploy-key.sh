#!/usr/bin/env bash
# Confirms fleet-ssh still holds the registered read-only deploy key and no password
set -uo pipefail

fail() { echo "FAIL: $*"; exit 1; }

PUBLIC_KEY="$(kubectl -n flux-system get secret fleet-ssh -o jsonpath='{.data.identity\.pub}' 2>/dev/null | base64 -d 2>/dev/null | awk '{print $2}')"
[ -n "$PUBLIC_KEY" ] || fail "the Secret fleet-ssh has no identity.pub key."
KEYS="$(kubectl -n flux-system get secret fleet-ssh -o jsonpath='{.data}' 2>/dev/null)"
case "$KEYS" in *'"identity"'*) ;; *) fail "the Secret fleet-ssh has no identity key." ;; esac
case "$KEYS" in *'"password"'*) fail "the Secret fleet-ssh must not hold a password." ;; esac
DEPLOY_KEYS="$(kubectl -n gitea exec deploy/tester -- \
  curl -fsS -u gitops:gitops-password http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/keys 2>/dev/null)"
READ_ONLY="$(printf '%s' "$DEPLOY_KEYS" | kubectl -n gitea exec -i deploy/tester -- \
  jq -r --arg k "$PUBLIC_KEY" '[.[] | select(.key | contains($k)) | .read_only] | first // "missing"' 2>/dev/null)"
[ "$READ_ONLY" = "true" ] || fail "the public key of fleet-ssh is not a read-only deploy key of gitops/fleet (read_only: ${READ_ONLY:-unknown}). Do not replace the key; fix known_hosts."
echo "PASS: fleet-ssh keeps the registered read-only deploy key and holds no password."
