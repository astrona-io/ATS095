# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** OCI sources

## Scenario

A colleague moved the podinfo delivery from Git to the OCI registry at `registry.localtest.me:5001` and went on holiday. They left an `OCIRepository` and a Flux `Kustomization`, both named `podinfo` in `flux-system`, and a note: "the cluster should run the newest 1.x release". Nothing is deployed. The registry holds the releases `1.0.0`, `1.1.0` and `2.0.0` of `podinfo-manifests`.

Look at the state first:

```sh
flux get sources oci
flux get kustomizations
kubectl get namespace podinfo
```

The registry uses plain HTTP. This environment has no Git server, and you do not need to push anything.

## Your task

1. Find every reason why the `OCIRepository` `podinfo` cannot fetch a release.
2. Find why the Flux `Kustomization` `podinfo` applies nothing.
3. Fix both objects so that the cluster follows the newest 1.x release, now and in future.

## Constraints

- Fix the `OCIRepository` and the Flux `Kustomization` in place. Do not delete and recreate them, and do not create new Flux objects.
- Follow a semver range. Do not pin a digest.
- Do not apply the application with `kubectl`.

## Done when

- The `OCIRepository` `podinfo` has the address `oci://registry.localtest.me:5001/podinfo-manifests`, allows plain HTTP, follows a semver range, and is `Ready` on a `1.1.0@sha256:` revision.
- The Flux `Kustomization` `podinfo` reads that `OCIRepository`, is `Ready` on the same revision, and `podinfo` runs the 3 replicas of release `1.1.0`.
