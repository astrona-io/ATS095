# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** operating source-controller

## Scenario

After a platform migration the cluster fetches nothing new, and the team that owns `team-b` complains. You operate source-controller. Four things are wrong; each shows up in a different place:

- source-controller reconciles one source at a time, while the platform team expects 6 sources soon.
- The `GitRepository` `fleet` cannot fetch.
- The `GitRepository` `platform` is not fetching.
- The Flux `Kustomization` `team-b-apps` in the namespace `team-b` applies nothing, and kustomize-controller runs with `--no-cross-namespace-refs=true`.

The private repository `gitops/fleet` holds `apps/podinfo` and `tenants/team-b`; `gitops/platform` holds `podinfo-settings`. Gitea accepts the user `gitops` with the password `gitops-password`. The Secrets `fleet-auth` and `platform-auth` in `flux-system` are correct.

For commands that call Gitea from your machine, start the port-forward in a second terminal first, and leave it running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

## Your task

1. Read the state: `flux get sources git`, `flux get kustomizations -A`, the args of source-controller.
2. Raise the concurrency of source-controller to at least 6 with the form `--concurrent=<n>`.
3. Make `fleet` and `platform` `Ready`, and both Flux Kustomizations `podinfo` and `platform-settings` apply the revision of their source.
4. Give team B a source of its own in `team-b` and apply `team-b-apps` as the ServiceAccount `team-b`.

## Constraints

- Keep the names `fleet`, `platform`, `podinfo`, `platform-settings` and `team-b-apps`.
- Keep `--no-cross-namespace-refs=true` and `--storage-path=/data`. Do not widen the rights of the ServiceAccount `team-b`.
- Do not change anything in the Git repositories.

## Done when

- source-controller has exactly one `--concurrent=<n>` with `n` at least 6 and is rolled out.
- `fleet` follows `main`, `platform` is not suspended, both are `Ready`, and `podinfo` and `platform-settings` apply their revisions.
- `team-b-apps` is `Ready` through a `GitRepository` in `team-b` as the ServiceAccount `team-b`, the ConfigMap `team-b-config` exists, and `team-b` cannot create namespaces.
