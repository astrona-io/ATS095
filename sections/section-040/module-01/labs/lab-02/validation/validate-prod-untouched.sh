#!/usr/bin/env bash
# Confirms nothing from the prod/ folder of the bucket reached the cluster
set -uo pipefail
if kubectl get namespace podinfo-prod >/dev/null 2>&1; then
  echo "FAIL: the namespace podinfo-prod exists; the prod/ folder must not be applied."; exit 1
fi
echo "PASS: nothing from prod/ was applied."
