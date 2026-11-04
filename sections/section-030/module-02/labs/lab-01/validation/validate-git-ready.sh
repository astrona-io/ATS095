#!/usr/bin/env bash
# Confirms the GitRepository podinfo-git is Ready on the branch master
set -uo pipefail
fail() { echo "FAIL: $*"; exit 1; }

BRANCH="$(kubectl -n flux-system get gitrepository podinfo-git -o jsonpath='{.spec.ref.branch}' 2>/dev/null)"
READY="$(kubectl -n flux-system get gitrepository podinfo-git -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
REV="$(kubectl -n flux-system get gitrepository podinfo-git -o jsonpath='{.status.artifact.revision}' 2>/dev/null)"
[ "$BRANCH" = "master" ] || fail "the GitRepository must follow the branch master (found: '$BRANCH')."
[ "$READY" = "True" ] || fail "the GitRepository podinfo-git is not Ready."
case "$REV" in master@*) ;; *) fail "the GitRepository revision is '$REV'; it must start with master@." ;; esac
echo "PASS: the GitRepository podinfo-git is Ready at $REV."
