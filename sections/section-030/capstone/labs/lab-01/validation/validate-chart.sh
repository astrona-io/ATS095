#!/usr/bin/env bash
# Confirms the HelmChart of the release uses the HelmRepository podinfo and is Ready on a 6.x version
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

LINE="$(kubectl get helmcharts -A -o jsonpath='{range .items[*]}{.spec.chart}{" "}{.spec.sourceRef.name}{" "}{.status.artifact.revision}{" "}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' 2>/dev/null \
  | awk '$1=="podinfo" && $2=="podinfo"' | head -1)"
[ -n "$LINE" ] || fail "no HelmChart fetches the chart podinfo from the HelmRepository podinfo."
REVISION="$(echo "$LINE" | awk '{print $3}')"
READY="$(echo "$LINE" | awk '{print $4}')"
[ "$READY" = "True" ] || fail "the HelmChart of the release is not Ready."
case "$REVISION" in 6.*) ;; *) fail "the HelmChart resolved '$REVISION'; it must resolve a 6.x version." ;; esac
echo "PASS: the HelmChart of the release is Ready at chart version $REVISION."
