#!/usr/bin/env bash
# Creates the starting state for ats-095-capstone-010: three release tags,
# the newest of which (v2.0.0) uses an image that does not exist, a docs
# folder in every release, and a GitRepository that follows `>=1.0.0`.
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

echo "[lab] Tagging v1.0.0 (1 replica), v1.2.0 (2 replicas) and v2.0.0 (an image that does not exist)..."
if ! gitea_api GET "/repos/$GIT_USER/$REPO/tags/v1.0.0" >/dev/null 2>&1; then
  create_tag "$REPO" v1.0.0
  sed 's/replicas: 1/replicas: 2/' "$MANIFESTS/repo/apps/podinfo/deployment.yaml" \
    | put_file "$REPO" apps/podinfo/deployment.yaml "Release 1.2.0: 2 replicas"
  create_tag "$REPO" v1.2.0
  sed -e 's/replicas: 1/replicas: 2/' -e 's|podinfo:6.15.0|podinfo:9.9.9|' "$MANIFESTS/repo/apps/podinfo/deployment.yaml" \
    | put_file "$REPO" apps/podinfo/deployment.yaml "Release 2.0.0: move to podinfo 9.9.9"
  create_tag "$REPO" v2.0.0
fi

echo "[lab] Connecting Flux to gitops/fleet with a semver range that has no upper bound..."
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username="$GIT_USER" --password="$GIT_PASSWORD"
kubectl apply -f "$MANIFESTS/flux-sync.yaml"
kubectl -n flux-system wait gitrepository/fleet --for=condition=Ready --timeout=180s || true

echo "[lab] Recording the objects, so a delete and recreate can be detected..."
kubectl -n flux-system create configmap capstone-baseline \
  --from-literal=gitrepository="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.metadata.uid}')" \
  --from-literal=kustomization="$(kubectl -n flux-system get kustomization podinfo -o jsonpath='{.metadata.uid}')" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready. podinfo follows v2.0.0, which never becomes healthy."
flux get sources git || true
