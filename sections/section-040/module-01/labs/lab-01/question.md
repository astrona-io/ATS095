# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Bucket sources and reconciliation triggers

## Scenario

A build job writes the podinfo manifests to the bucket `podinfo` on the S3-compatible server in the namespace `s3`. The cluster should deliver whatever the bucket holds. The platform team allows source checks every 30 minutes and no more often. Releases are still expected in the cluster within a minute of upload, because the build job will request a reconciliation after each upload.

```sh
kubectl -n s3 exec deploy/s3-client -- aws s3 ls s3://podinfo
```

The server is at `s3.s3.svc.cluster.local:9000`, over plain HTTP, with the lab-only access key `flux-s3` and secret key `flux-s3-secret`. The pod `s3-client` in `s3` has the `aws` command-line tool, already set up for it.

## Your task

1. Create a Secret `s3-credentials` in `flux-system` with the access key and secret key.
2. Create a `Bucket` named `podinfo` in `flux-system` that reads the bucket `podinfo` every **30 minutes**.
3. Create a Flux `Kustomization` named `podinfo` in `flux-system` that applies the manifests at the root of the bucket, with pruning on.
4. Act as the build job: change `deployment.yaml` in the bucket to 3 replicas, upload it, and get the change into the cluster at once.

## Constraints

- Keep the interval of the `Bucket` at `30m`. Do not shorten it to pick up the change.
- Do not apply the manifests with `kubectl` yourself.

## Done when

- The `Bucket` `podinfo` reads the bucket `podinfo` over HTTP with the Secret `s3-credentials`, has the interval `30m`, and is `Ready`.
- The Secret `s3-credentials` holds the keys `accesskey` and `secretkey`.
- `deployment.yaml` in the bucket asks for 3 replicas.
- The Flux `Kustomization` `podinfo` reads the `Bucket`, is `Ready` on its current revision, and `podinfo` runs 3 ready replicas.
