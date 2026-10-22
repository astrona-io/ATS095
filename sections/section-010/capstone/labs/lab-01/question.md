# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Git sources

## Scenario

The team behind `gitops/fleet` releases with Git tags. The cluster was meant to run the newest 1.x release, so a colleague set the `GitRepository` `fleet` in `flux-system` to follow a semver range. This morning someone tagged `v2.0.0`, the first release of the next major version, and `podinfo` stopped becoming healthy.

The repository holds three release tags: `v1.0.0`, `v1.2.0` and `v2.0.0`. Every release also carries a `docs` folder that the cluster never needs. Look at the state first:

```sh
flux get sources git
flux get kustomizations
kubectl -n podinfo get pods
```

## Your task

1. Find out which release the cluster follows and why `podinfo` is not healthy.
2. Restrict `fleet` so that it follows only 1.x releases, and keeps following new 1.x releases when they are tagged.
3. Leave the `docs` folder out of the artifact of `fleet`.
4. Confirm that `podinfo` runs release `v1.2.0`.

## Constraints

- Do not change anything in the repository: every release is already tagged, and tags are not moved.
- Follow a semver range. Do not pin a `tag`, a full reference (`name`) or a `commit`.
- Fix the `GitRepository` `fleet` and the Flux `Kustomization` `podinfo` in place. Do not delete and recreate them.
- Do not apply the application with `kubectl`.

## Done when

- `fleet` follows a semver range and is `Ready` on a `v1.2.0@sha1:` revision.
- The artifact of `fleet` holds `apps/podinfo` and no `docs` folder.
- The Flux `Kustomization` `podinfo` is `Ready` on the same revision, and `podinfo` runs `ghcr.io/stefanprodan/podinfo:6.15.0` with 2 ready replicas.
