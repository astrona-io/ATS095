# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** troubleshooting sources

## Scenario

Three `GitRepository` objects in the namespace `flux-system` are in trouble after a cleanup: `fleet`, `platform` and `fleet-tags`. The Flux `Kustomization` `podinfo` (source `fleet`) and the Flux `Kustomization` `platform-settings` (source `platform`) apply nothing. Each source has its own cause. Read the conditions and events of each source before you change anything:

```sh
flux get sources git
kubectl -n flux-system describe gitrepository fleet
flux events --for GitRepository/platform
```

For commands that call Gitea from your machine, start the port-forward in a second terminal first, and leave it running. If `gitea.localtest.me` does not resolve on your machine, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

## Your task

1. Find the cause for each of the three sources.
2. Fix each cause in the cluster. The Git repositories are correct.
3. Confirm that both Flux Kustomizations apply the revision of their source.

## Constraints

- Keep the names `fleet`, `platform`, `platform-auth`, `fleet-tags`, `podinfo` and `platform-settings`. Do not create new sources.
- `fleet-tags` keeps following the tag `v1.1.0`. `platform` keeps using the Secret `platform-auth`.
- Do not change anything in the Git repositories.

## Done when

- `fleet` follows `main` and is `Ready`; `podinfo` applies its revision.
- `platform` is `Ready` with the right credentials; `platform-settings` applies its revision and the ConfigMap `podinfo-settings` exists.
- `fleet-tags` is not suspended, is `Ready` and serves `v1.1.0@sha1:...`.
