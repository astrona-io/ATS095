# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Flux artifacts and the flux CLI

## Scenario

The cluster runs release `1.1.0` of `podinfo-manifests` from the registry at `registry.localtest.me:5001`, which uses plain HTTP and no sign-in. The `OCIRepository` `podinfo` follows the fixed tag `1.1.0`. The folder `apps/podinfo` on the branch `main` of `gitops/fleet` has changed since then, and it asks for 2 replicas. The release process asks for two things: every release records where it came from, and production follows a digest, not a tag.

For commands that call Gitea or the registry from your machine, start the port-forwards in a second terminal first, and leave them running. If the names do not resolve, add `127.0.0.1 gitea.localtest.me registry.localtest.me` to `/etc/hosts`:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 &
kubectl -n registry port-forward svc/registry 5001:5001
```

## Your task

1. Push `apps/podinfo` from the current `main` of `gitops/fleet` as release `1.2.0` with `flux push artifact`. It must carry the Git URL as the source and `main@sha1:<commit>` of the current head of `main` as the revision.
2. Find the digest of release `1.2.0` in the registry.
3. Pin the `OCIRepository` `podinfo` to that digest and remove the tag.
4. Confirm that the Flux `Kustomization` `podinfo` applies the revision and runs 2 replicas.

## Constraints

- Keep the releases `1.0.0` and `1.1.0` in the registry.
- Edit the `OCIRepository` in place. Do not delete and recreate it.

## Success criteria

- The registry holds `1.2.0` with the annotations `org.opencontainers.image.source` and `org.opencontainers.image.revision` set from Git.
- `spec.ref.digest` is the digest of `1.2.0` and `spec.ref.tag` is gone.
- `podinfo` is Ready, and the Deployment runs 2 ready replicas.
