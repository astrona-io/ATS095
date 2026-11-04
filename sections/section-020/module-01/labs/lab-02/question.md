# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** OCI sources and troubleshooting

## Scenario

A teammate created the `OCIRepository` `podinfo` in the namespace `flux-system` to deliver the podinfo manifests from the registry at `registry.localtest.me:5001`. Nothing arrives: the Flux `Kustomization` `podinfo` waits for the source. The registry holds the releases `1.0.0`, `1.1.0` and `1.2.0-rc.1` of the repository `podinfo-manifests`. The cluster must run release `1.1.0`.

Start by reading the state:

```sh
flux get sources oci
kubectl -n flux-system describe ocirepository podinfo
flux events --for OCIRepository/podinfo
```

## Your task

1. Find from the conditions and events of `podinfo` why it cannot fetch. There is more than one cause, and the second only appears after the first is fixed.
2. Fix each cause so that the `OCIRepository` follows the tag `1.1.0`.
3. Confirm that the Flux `Kustomization` `podinfo` applies the revision of the `OCIRepository`.

## Constraints

- Fix the `OCIRepository` in place. Do not delete and recreate it.
- Keep a fixed tag. Do not use a digest or a semver range.
- Do not change the registry.

## Success criteria

- `podinfo` is Ready and its revision starts with `1.1.0@sha256:`.
- The Flux `Kustomization` `podinfo` is Ready at that revision and the Deployment runs 3 ready replicas.
