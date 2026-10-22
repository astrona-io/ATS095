# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** OCI sources

## Scenario

The cluster runs the podinfo manifests from the OCI registry at `registry.localtest.me:5001`. The `OCIRepository` `podinfo` in `flux-system` was set to the tag `1.0.0` during the first rollout and never changed, so newer releases never arrive. The registry now holds these releases of `podinfo-manifests`:

| Release | What it is |
| --- | --- |
| `1.0.0` | The first release |
| `1.1.0` | A stable release |
| `1.2.0-rc.1` | A release candidate, not for this cluster |
| `2.0.0` | The next major version, not for this cluster |

The team also wants to release the manifests that are on `main` in `gitops/fleet` today, as version `1.3.0`.

Start the port-forwards in a second terminal first, and leave them running. If the names do not resolve on your machine, add `127.0.0.1 gitea.localtest.me registry.localtest.me` to `/etc/hosts`:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 &
kubectl -n registry port-forward svc/registry 5001:5001
```

## Your task

1. Change the `OCIRepository` `podinfo` so that it always follows the newest stable 1.x release: no release candidates and no 2.x.
2. Push the folder `apps/podinfo` from `main` of `gitops/fleet` to the registry as `podinfo-manifests:1.3.0`, with the Git address and the commit as its source and revision.
3. Confirm that the cluster runs release `1.3.0`.

## Constraints

- Keep the names `podinfo` (the `OCIRepository` and the Flux `Kustomization`) and the repository `podinfo-manifests`.
- Do not pin a digest. Do not delete releases from the registry.
- Do not apply the application with `kubectl`.

## Done when

- The `OCIRepository` `podinfo` follows a semver range and is `Ready` on a `1.3.0@sha256:` revision.
- The registry holds `podinfo-manifests:1.3.0`, and `2.0.0` is still there.
- The Flux `Kustomization` `podinfo` is `Ready` on the same revision, and `podinfo` runs the 2 replicas of release `1.3.0`.
