#!/usr/bin/env bash
# Lab ats-095-lab-050-02: connects Flux to gitops/fleet and sets --concurrent=1 on source-controller.
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

set_args() {
  # set_args DEPLOYMENT JQ_FILTER_ON_ARGS: rewrites the args of the first container.
  kubectl -n flux-system get deployment "$1" -o json \
    | jq "(.spec.template.spec.containers[0].args) |= ($2)" \
    | kubectl replace -f - >/dev/null
  kubectl -n flux-system rollout status deployment/"$1" --timeout=180s
}

echo "[lab] Creating the Git credentials Secret fleet-auth..."
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username="$GIT_USER" --password="$GIT_PASSWORD"

echo "[lab] Connecting Flux to gitops/fleet..."
kubectl apply -f "$MANIFESTS/start/flux-sync.yaml"
kubectl -n flux-system wait gitrepository/fleet --for=condition=Ready --timeout=180s
kubectl -n flux-system wait kustomization/podinfo --for=condition=Ready --timeout=300s

echo "[lab] Setting source-controller to --concurrent=1 ..."
set_args source-controller '(map(select(startswith("--concurrent")|not))) + ["--concurrent=1"]'
echo "[lab] Starting state ready."
kubectl -n flux-system get deployment source-controller -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}'
