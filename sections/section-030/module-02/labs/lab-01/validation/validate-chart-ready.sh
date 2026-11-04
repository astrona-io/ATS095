#!/usr/bin/env bash
# Confirms the HelmChart podinfo-git is Ready and built from the directory charts/podinfo of the GitRepository
set -uo pipefail
fail() { echo "FAIL: $*"; exit 1; }
get() { kubectl -n flux-system get helmchart podinfo-git -o jsonpath="{$1}" 2>/dev/null; }

KIND="$(get .spec.sourceRef.kind)"
NAME="$(get .spec.sourceRef.name)"
CHART="$(get .spec.chart)"
READY="$(get '.status.conditions[?(@.type=="Ready")].status')"
REV="$(get .status.artifact.revision)"
[ "$KIND" = "GitRepository" ] && [ "$NAME" = "podinfo-git" ] || fail "the HelmChart must still read from the GitRepository podinfo-git (found: $KIND/$NAME)."
case "$CHART" in ./charts/podinfo|charts/podinfo) ;; *) fail "the chart path is '$CHART'; the chart is in charts/podinfo." ;; esac
[ "$READY" = "True" ] || fail "the HelmChart podinfo-git is not Ready."
[ -n "$REV" ] || fail "the HelmChart has no artifact revision."
echo "PASS: the HelmChart podinfo-git is Ready at $REV."
