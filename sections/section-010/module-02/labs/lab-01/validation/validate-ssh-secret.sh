#!/usr/bin/env bash
# Confirms known_hosts of fleet-ssh holds the real host key of the Gitea SSH server for [gitea.localtest.me]:2222
set -uo pipefail

fail() { echo "FAIL: $*"; exit 1; }

KNOWN_HOSTS="$(kubectl -n flux-system get secret fleet-ssh -o jsonpath='{.data.known_hosts}' 2>/dev/null | base64 -d 2>/dev/null)"
[ -n "$KNOWN_HOSTS" ] || fail "the Secret fleet-ssh has no known_hosts key."
SERVER_KEYS="$(kubectl -n gitea exec deploy/tester -- ssh-keyscan -p 2222 gitea-http.gitea 2>/dev/null | awk '!/^#/ {print $3}')"
[ -n "$SERVER_KEYS" ] || fail "could not read the host keys of the Gitea SSH server."
MATCHED=""
while read -r host _type key _rest; do
  [ "$host" = "[gitea.localtest.me]:2222" ] || continue
  if printf '%s\n' "$SERVER_KEYS" | awk -v want="$key" '$0 == want {found = 1} END {exit !found}'; then
    MATCHED="yes"
  fi
done <<< "$KNOWN_HOSTS"
[ -n "$MATCHED" ] || fail "known_hosts has no entry for [gitea.localtest.me]:2222 with a host key of the Gitea server."
echo "PASS: known_hosts holds a real host key of the Gitea server for [gitea.localtest.me]:2222."
