# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Bucket prefix and ignore rules

## Scenario

One bucket, `releases`, on the S3-compatible server in the namespace `s3`, holds the manifests of two environments: the folder `staging/` and the folder `prod/`. This cluster is the staging cluster, so it must never download or apply anything from `prod/`. Someone also left a draft in `staging/draft/` that must not be applied.

```sh
kubectl -n s3 exec deploy/s3-client -- aws s3 ls s3://releases --recursive
```

The `Bucket` `releases` and the Flux `Kustomization` `releases` in `flux-system` already exist, and the Secret `s3-credentials` is in place. The Kustomization is not Ready.

## Your task

1. Find out why the Flux `Kustomization` `releases` is not Ready.
2. Change the `Bucket` `releases` so that source-controller lists only the objects under `staging/`.
3. Change the `Bucket` so that the folder `draft/` is left out of the artifact.
4. Get the Flux `Kustomization` Ready on the new revision, with the staging manifests applied.

## Constraints

- Keep the interval of the `Bucket` at `30m`.
- Do not delete or change objects in the bucket.
- Do not apply the manifests with `kubectl` yourself.

## Success criteria

- `spec.prefix` of the `Bucket` is `staging/`, and `spec.ignore` excludes the draft folder.
- The Flux `Kustomization` `releases` is `Ready` on the revision of the `Bucket`, and `podinfo` in the namespace `podinfo-staging` runs 2 ready replicas.
- The namespace `podinfo-prod` does not exist.
