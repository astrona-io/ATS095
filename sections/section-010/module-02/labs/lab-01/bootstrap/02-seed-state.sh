#!/usr/bin/env bash
# Creates the starting state for ats-095-lab-010-02: the GitRepository fleet
# uses an SSH address without the port and a Secret fleet-ssh whose
# known_hosts holds the host key of a different server. The deploy key in
# fleet-ssh is already registered in Gitea as read-only. Two faults, both
# visible in the conditions of fleet; the task is to find and fix them.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

GIT_USER="gitops"
GIT_PASSWORD="gitops-password"

gitea_api() {
  # gitea_api METHOD PATH [JSON]: calls the Gitea API from the tester pod.
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    printf '%s' "$body" | kubectl -n gitea exec -i deploy/tester -- \
      curl -fsS -u "$GIT_USER:$GIT_PASSWORD" -X "$method" -H 'Content-Type: application/json' \
      --data-binary @- "http://gitea-http.gitea:3000/api/v1$path"
  else
    kubectl -n gitea exec deploy/tester -- \
      curl -fsS -u "$GIT_USER:$GIT_PASSWORD" -X "$method" "http://gitea-http.gitea:3000/api/v1$path"
  fi
}

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "[lab] Creating two SSH key pairs in the tester pod: the Flux key and a key of another server..."
kubectl -n gitea exec deploy/tester -- sh -c \
  "rm -rf /tmp/keys && mkdir -p /tmp/keys && ssh-keygen -q -t ed25519 -N '' -C flux-lab -f /tmp/keys/flux && ssh-keygen -q -t ed25519 -N '' -C other-host -f /tmp/keys/otherhost"
kubectl -n gitea exec deploy/tester -- cat /tmp/keys/flux > "$WORK_DIR/identity"
kubectl -n gitea exec deploy/tester -- cat /tmp/keys/flux.pub > "$WORK_DIR/identity.pub"
OTHER_KEY="$(kubectl -n gitea exec deploy/tester -- awk '{print $1" "$2}' /tmp/keys/otherhost.pub)"
printf '[gitea.localtest.me]:2222 %s\n' "$OTHER_KEY" > "$WORK_DIR/known_hosts"

echo "[lab] Registering the Flux public key as a read-only deploy key of gitops/fleet..."
DEPLOY_KEY="$(tr -d '\n' < "$WORK_DIR/identity.pub")"
gitea_api POST "/repos/$GIT_USER/fleet/keys" \
  "{\"title\":\"flux-lab\",\"key\":\"$DEPLOY_KEY\",\"read_only\":true}" >/dev/null

echo "[lab] Creating the Secret fleet-ssh with the wrong known_hosts..."
kubectl -n flux-system create secret generic fleet-ssh \
  --from-file=identity="$WORK_DIR/identity" \
  --from-file=identity.pub="$WORK_DIR/identity.pub" \
  --from-file=known_hosts="$WORK_DIR/known_hosts"

kubectl apply -f "$MANIFESTS/flux-sync.yaml"
sleep 10

echo "[lab] Starting state ready: fleet cannot fetch over SSH."
flux get sources git || true
