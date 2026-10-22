#!/usr/bin/env bash
# OS prep for the "Sync From A Bucket And Control When Flux Fetches" playground (`ats-095-playground-040-01`).
#
# Environment preparation only. There is no task and no grading. It installs
# the Flux CLI and controllers and an S3-compatible server, and fills the
# bucket podinfo with the podinfo manifests.
set -euo pipefail

FLUX_VERSION="2.9.6"
BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# Pin the version rather than accepting whatever flux happens to be on the
# machine: the CLI installs controllers of its own version, and the course is
# written against ${FLUX_VERSION}.
have_version=""
command -v flux >/dev/null 2>&1 && \
  have_version=$(flux version --client 2>/dev/null | awk '/flux:/{print $2}' | sed 's/^v//')
if [ "$have_version" != "$FLUX_VERSION" ]; then
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"
  case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
  WORK="$(mktemp -d)"
  trap 'rm -rf "$WORK"' EXIT
  echo "[playground] Downloading Flux CLI ${FLUX_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_${OS}_${ARCH}.tar.gz" \
    | tar -xz -C "$WORK" flux
  install -m 0755 "$WORK/flux" "$BIN_DIR/flux"
fi
flux version --client

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[playground] Applying the starting workloads..."
kubectl apply -f "$MANIFESTS/lab-start.yaml"
kubectl -n s3 rollout status deployment/versitygw --timeout=300s
kubectl -n s3 rollout status deployment/s3-client --timeout=300s

echo "[playground] Installing the Flux controllers..."
flux install
flux check

s3() {
  # s3 ARGS...: runs `aws s3 ARGS` in the s3-client pod.
  kubectl -n s3 exec -i deploy/s3-client -- aws s3 "$@"
}

fill_bucket() {
  # fill_bucket BUCKET: creates BUCKET and uploads the files of manifests/bucket.
  local bucket="$1" file
  s3 ls "s3://$bucket" >/dev/null 2>&1 || s3 mb "s3://$bucket"
  for file in namespace.yaml deployment.yaml service.yaml kustomization.yaml; do
    s3 cp - "s3://$bucket/$file" < "$MANIFESTS/bucket/$file"
  done
}

echo "[playground] Creating the bucket podinfo and uploading the podinfo manifests..."
fill_bucket podinfo

echo "[playground] Ready."
s3 ls s3://podinfo
