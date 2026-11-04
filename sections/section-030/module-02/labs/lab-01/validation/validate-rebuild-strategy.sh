#!/usr/bin/env bash
# Confirms the HelmChart rebuilds on every new source revision and was fixed in place
set -uo pipefail
fail() { echo "FAIL: $*"; exit 1; }

STRATEGY="$(kubectl -n flux-system get helmchart podinfo-git -o jsonpath='{.spec.reconcileStrategy}' 2>/dev/null)"
REV="$(kubectl -n flux-system get helmchart podinfo-git -o jsonpath='{.status.artifact.revision}' 2>/dev/null)"
[ "$STRATEGY" = "Revision" ] || fail "reconcileStrategy is '$STRATEGY'; it must be Revision."
case "$REV" in *+*) ;; *) fail "the chart revision '$REV' has no source revision suffix yet. Reconcile the chart." ;; esac
for kind in gitrepository helmchart; do
  want="$(kubectl -n flux-system get configmap lab-baseline -o jsonpath="{.data.$kind}" 2>/dev/null)"
  have="$(kubectl -n flux-system get "$kind" podinfo-git -o jsonpath='{.metadata.uid}' 2>/dev/null)"
  [ -n "$want" ] && [ "$want" = "$have" ] || fail "the $kind podinfo-git was deleted and recreated. Fix it in place."
done
echo "PASS: the chart rebuilds on every revision ($REV) and both objects were fixed in place."
