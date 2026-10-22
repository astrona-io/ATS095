#!/usr/bin/env bash
# Creates the starting state for ats-095-lab-010-01: the GitRepository fleet
# reads gitops/fleet over HTTP with the password Secret fleet-auth, and the
# Flux Kustomization podinfo applies apps/podinfo. Everything works; the task
# is to move the source to SSH.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

GIT_USER="gitops"
GIT_PASSWORD="gitops-password"
REPO="fleet"

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

put_file() {
  # put_file REPO PATH MESSAGE < CONTENT: creates or updates one file on main.
  local repo="$1" path="$2" message="$3" content sha
  content="$(base64 | tr -d '\n')"
  sha="$(kubectl -n gitea exec deploy/tester -- sh -c \
    "curl -fsS -u '$GIT_USER:$GIT_PASSWORD' http://gitea-http.gitea:3000/api/v1/repos/$GIT_USER/$repo/contents/$path 2>/dev/null | jq -r '.sha // empty'" || true)"
  if [ -n "$sha" ]; then
    gitea_api PUT "/repos/$GIT_USER/$repo/contents/$path" \
      "{\"content\":\"$content\",\"message\":\"$message\",\"branch\":\"main\",\"sha\":\"$sha\"}" >/dev/null
  else
    gitea_api POST "/repos/$GIT_USER/$repo/contents/$path" \
      "{\"content\":\"$content\",\"message\":\"$message\",\"branch\":\"main\"}" >/dev/null
  fi
}

create_tag() {
  # create_tag REPO TAG: tags the current head of main.
  gitea_api POST "/repos/$GIT_USER/$1/tags" "{\"tag_name\":\"$2\",\"target\":\"main\"}" >/dev/null
}

main_commit() {
  # main_commit REPO: prints the commit id at the head of main.
  kubectl -n gitea exec deploy/tester -- sh -c \
    "curl -fsS -u '$GIT_USER:$GIT_PASSWORD' http://gitea-http.gitea:3000/api/v1/repos/$GIT_USER/$1/branches/main | jq -r .commit.id"
}

create_repo_from_dir() {
  # create_repo_from_dir REPO DIR: creates a private repository and commits
  # every file of DIR to main, unless the repository already holds files.
  local repo="$1" dir="$2" file
  gitea_api GET "/repos/$GIT_USER/$repo" >/dev/null 2>&1 || \
    gitea_api POST "/user/repos" "{\"name\":\"$repo\",\"auto_init\":true,\"default_branch\":\"main\",\"private\":true}" >/dev/null
  if gitea_api GET "/repos/$GIT_USER/$repo/contents/apps" >/dev/null 2>&1; then
    return 0
  fi
  (cd "$dir" && find . -type f | sed 's|^\./||' | sort) | while read -r file; do
    put_file "$repo" "$file" "Add $file" < "$dir/$file"
  done
}

echo "[lab] Connecting Flux to gitops/fleet with the password Secret fleet-auth..."
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username="$GIT_USER" --password="$GIT_PASSWORD"
kubectl apply -f "$MANIFESTS/flux-sync.yaml"
kubectl -n flux-system wait gitrepository/fleet --for=condition=Ready --timeout=180s
kubectl -n flux-system wait kustomization/podinfo --for=condition=Ready --timeout=300s

echo "[lab] Starting state ready: Flux reads gitops/fleet over HTTP with a password."
flux get sources git
echo "[lab] Moving it to a read-only SSH deploy key is the task."
