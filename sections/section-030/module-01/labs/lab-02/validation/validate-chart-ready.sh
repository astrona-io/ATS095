#!/usr/bin/env bash
# Confirms the HelmChart podinfo is Ready on a 6.x chart version from the HelmRepository podinfo
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

SOURCE="$(field helmchart podinfo .spec.sourceRef.name)"
CHART="$(field helmchart podinfo .spec.chart)"
REVISION="$(field helmchart podinfo .status.artifact.revision)"
[ "$SOURCE" = "podinfo" ] || fail "the HelmChart podinfo must still use the HelmRepository podinfo (found: $SOURCE)."
[ "$CHART" = "podinfo" ] || fail "the HelmChart must still fetch the chart podinfo (found: $CHART)."
[ "$(ready helmchart podinfo)" = "True" ] || fail "the HelmChart podinfo is not Ready."
case "$REVISION" in 6.*) ;; *) fail "the HelmChart podinfo is at '$REVISION'; it must resolve a 6.x version." ;; esac
echo "PASS: the HelmChart podinfo is Ready at chart version $REVISION."
