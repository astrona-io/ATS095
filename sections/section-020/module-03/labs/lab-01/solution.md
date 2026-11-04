# Solution

## Step 1: Push the release

Clone `gitops/fleet`, keep the commit and push the folder with the source and the revision:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
COMMIT="$(git rev-parse HEAD)"
flux push artifact oci://registry.localtest.me:5001/podinfo-manifests:1.2.0 \
  --path=./apps/podinfo \
  --source="http://gitea.localtest.me:3000/gitops/fleet.git" \
  --revision="main@sha1:$COMMIT" \
  --insecure-registry
```

## Step 2: Find the digest

```sh
flux list artifacts oci://registry.localtest.me:5001/podinfo-manifests --insecure-registry
DIGEST="$(curl -fsSI -H 'Accept: application/vnd.oci.image.manifest.v1+json' http://registry.localtest.me:5001/v2/podinfo-manifests/manifests/1.2.0 | tr -d '\r' | awk 'tolower($1)=="docker-content-digest:" {print $2}')"
echo "$DIGEST"
```

## Step 3: Pin the digest

A merge patch with `null` removes the tag:

```sh
kubectl -n flux-system patch ocirepository podinfo --type=merge -p "{\"spec\":{\"ref\":{\"tag\":null,\"digest\":\"$DIGEST\"}}}"
flux reconcile source oci podinfo
flux reconcile kustomization podinfo
```

## Step 4: Check

```sh
flux get sources oci
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

Then run `astrona submit`.
