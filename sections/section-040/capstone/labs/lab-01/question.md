# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Bucket sources and artifacts

## Scenario

A build job fills the bucket `podinfo` on the S3-compatible server in the namespace `s3`, and the manifests sit at the root of the bucket. A colleague wired the cluster to it with three objects in `flux-system`: the Secret `s3-credentials`, the `Bucket` `podinfo` and the Flux `Kustomization` `podinfo`. podinfo was never deployed.

```sh
flux get sources bucket
flux get kustomizations
kubectl -n s3 exec deploy/s3-client -- aws s3 ls
```

The server is at `s3.s3.svc.cluster.local:9000`, over plain HTTP, with the lab-only access key `flux-s3` and secret key `flux-s3-secret`.

## Your task

1. Find every reason why the `Bucket` `podinfo` produces no artifact.
2. Find why the Flux `Kustomization` `podinfo` applies nothing once the source works.
3. Fix all three objects so that podinfo runs from the bucket.

## Constraints

- Fix the `Bucket` and the Flux `Kustomization` in place. Do not delete and recreate them. You may replace the Secret.
- Do not change anything in the bucket, and do not apply the manifests with `kubectl` yourself.

## Done when

- The `Bucket` `podinfo` reads the bucket `podinfo` over plain HTTP and is `Ready`.
- The Secret `s3-credentials` holds the keys `accesskey` and `secretkey`.
- The Flux `Kustomization` `podinfo` applies the root of the bucket, is `Ready` on the `Bucket`'s current revision, and `podinfo` runs 2 ready replicas.
