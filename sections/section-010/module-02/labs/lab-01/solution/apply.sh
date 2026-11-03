#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# Step 1: read the real host keys of the Git server. The name
# gitea.localtest.me resolves to the Gitea Service inside the cluster.
HOST_KEYS="$(kubectl -n gitea exec deploy/tester -- ssh-keyscan -p 2222 gitea.localtest.me 2>/dev/null | grep -v '^#')"
ENCODED="$(printf '%s\n' "$HOST_KEYS" | base64 | tr -d '\n')"

# Step 2: replace known_hosts in the Secret and keep the key pair.
kubectl -n flux-system patch secret fleet-ssh --type=merge -p "{\"data\":{\"known_hosts\":\"$ENCODED\"}}"

# Step 3: add the port to the address of the GitRepository.
kubectl -n flux-system patch gitrepository fleet --type=merge -p \
  '{"spec":{"url":"ssh://git@gitea.localtest.me:2222/gitops/fleet.git"}}'
flux reconcile source git fleet --timeout=2m
flux reconcile kustomization podinfo --timeout=3m
