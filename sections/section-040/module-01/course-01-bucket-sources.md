# Bucket Sources On S3-Compatible Storage

The bucket `podinfo` holds a complete set of manifests, and nothing in the cluster reads it. This part connects it: a Secret with the access keys, a `Bucket` source that fetches the objects, and a Flux `Kustomization` that applies them. Along the way it shows what a bucket revision is, because a bucket has no commits and no tags.

## Give Flux the access keys

An S3 server identifies a client by an **access key** and a **secret key**, a pair like a user name and a password. For the default provider, `generic`, source-controller reads them from a Secret with exactly the keys `accesskey` and `secretkey`. Create it in `flux-system`, with the lab-only key pair of this server:

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system create secret generic s3-credentials \
  --from-literal=accesskey=flux-s3 \
  --from-literal=secretkey=flux-s3-secret
```

The other providers, `aws`, `gcp` and `azure`, can use the cloud's own identity instead of keys, for example a Kubernetes service account that the cloud trusts. On a cloud, that is the better choice, because no long-lived key sits in a Secret.

## Create the Bucket source

A `Bucket` names the server in `endpoint` (host and port, without a scheme), the bucket in `bucketName`, and the Secret in `secretRef`. This server uses plain HTTP, so `insecure: true` allows it; a real object store uses HTTPS and does not need it. The interval is long on purpose, 30 minutes, so the next part can show how to fetch without waiting. Save this as `bucket-podinfo.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: Bucket
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 30m
  provider: generic
  bucketName: podinfo
  endpoint: s3.s3.svc.cluster.local:9000
  insecure: true
  secretRef:
    name: s3-credentials
```

Apply it:

```sh
kubectl apply -f bucket-podinfo.yaml
```

Then check the result:

```sh
flux get sources bucket
```

The row for `podinfo` shows `READY` as `True` and a revision of the form `sha256:` followed by a long hash. source-controller listed every object in the bucket, downloaded them, and packed them into an artifact, the same `tar.gz` format it uses for Git.

## What a bucket revision is

A bucket has no commits, so source-controller makes its own revision. It builds a list of every object key with its **ETag**, a short value the server computes from the object's content, and leaves out the keys that the default ignore rules exclude. The `sha256` digest of that list is the revision.

Two facts follow. Any change to any object changes its ETag, so the revision changes. And uploading exactly the same content again gives the same ETags and the same revision, so source-controller sees nothing new and the cluster does nothing. The revision describes the content, not the time of the upload.

## Apply the manifests

The objects sit at the root of the bucket, so the Flux `Kustomization` reads the path `./`, and its `sourceRef` names the kind `Bucket`. Save this as `kustomization-podinfo.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 30m
  path: ./
  prune: true
  wait: true
  timeout: 2m
  sourceRef:
    kind: Bucket
    name: podinfo
```

Apply it:

```sh
kubectl apply -f kustomization-podinfo.yaml
```

Then check the result:

```sh
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

The Flux `Kustomization` is `Ready` on the same `sha256:` revision as the `Bucket`, and the Deployment runs 2 replicas, the value in the bucket's `deployment.yaml`. kustomize-controller treated the bucket's artifact exactly like a Git artifact: it built the folder with the Kustomize file `kustomization.yaml` and applied the result.

You can now connect a bucket to the cluster and read its revision. The open question is timing: with a 30-minute interval, a new upload waits up to half an hour, unless you ask Flux to fetch now.

## Common pitfalls

> [!WARNING]
> - **Other key names in the Secret.** The `generic` provider reads exactly `accesskey` and `secretkey`. Names such as `access_key` are ignored, and the server refuses the request.
> - **Expecting `http://` in `endpoint` to choose HTTP.** For the `generic` provider, give the host and port, and let `insecure` choose plain HTTP.
> - **A plain-HTTP server without `insecure: true`.** source-controller tries HTTPS and fails.
> - **The wrong path.** The objects of this bucket are at its root, so the path is `./`. A path that does not exist leaves the Flux `Kustomization` not ready while the `Bucket` is fine.
