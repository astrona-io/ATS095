#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

s3() {
  # s3 ARGS...: runs `aws s3 ARGS` in the s3-client pod.
  kubectl -n s3 exec -i deploy/s3-client -- aws s3 "$@"
}

# Step 1: the token and the Receiver for the Bucket.
kubectl -n flux-system create secret generic webhook-token \
  --from-literal=token="$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f - <<'EOF'
apiVersion: notification.toolkit.fluxcd.io/v1
kind: Receiver
metadata:
  name: podinfo-upload
  namespace: flux-system
spec:
  type: generic
  secretRef:
    name: webhook-token
  resources:
    - apiVersion: source.toolkit.fluxcd.io/v1
      kind: Bucket
      name: podinfo
EOF
kubectl -n flux-system wait receiver/podinfo-upload --for=condition=Ready --timeout=120s

# Step 2: act as the build job: upload 3 replicas.
s3 cp s3://podinfo/deployment.yaml - | sed 's/replicas: 2/replicas: 3/' | s3 cp - s3://podinfo/deployment.yaml

# Step 3: call the webhook from inside the cluster.
HOOK="$(kubectl -n flux-system get receiver podinfo-upload -o jsonpath='{.status.webhookPath}')"
kubectl -n s3 exec deploy/s3-client -- curl -fsS -X POST "http://webhook-receiver.flux-system.svc.cluster.local$HOOK"
kubectl -n flux-system wait kustomization/podinfo --for=jsonpath='{.status.lastAppliedRevision}'="$(kubectl -n flux-system get bucket podinfo -o jsonpath='{.status.artifact.revision}')" --timeout=180s || true
sleep 20
