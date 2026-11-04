# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** multi-tenant sources

## Scenario

The platform team runs one cluster for several teams. To stop a team from using sources that belong to someone else, kustomize-controller now runs with `--no-cross-namespace-refs=true`. Team A's Flux `Kustomization` `team-a-apps` in the namespace `team-a` still points at the `GitRepository` `fleet` in `flux-system`, so it applies nothing.

The namespace `team-a` has a ServiceAccount `team-a` with the ClusterRole `admin` bound in that namespace only. Team A's manifests are in the private repository `gitops/fleet` under `tenants/team-a`. Gitea accepts the user `gitops` with the password `gitops-password`.

```sh
kubectl -n team-a describe kustomization team-a-apps
```

For commands that call Gitea from your machine, start the port-forward in a second terminal first, and leave it running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

## Your task

1. Read why `team-a-apps` is blocked.
2. Give team A its own source: a `GitRepository` in the namespace `team-a` for `gitops/fleet` with its own Git credentials Secret in `team-a`.
3. Point `team-a-apps` at that source and make it apply as the ServiceAccount `team-a`.
4. Confirm the ConfigMap `team-a-config` appears in `team-a`.

## Constraints

- Keep `--no-cross-namespace-refs=true` on kustomize-controller. Do not remove it and do not bind more rights to the ServiceAccount.
- Do not copy the Secret from `flux-system` by hand with its namespace edited out of an export; create it in `team-a` with `flux create secret git`.
- Keep the Kustomization name `team-a-apps`.

## Done when

- `team-a-apps` is `Ready` and the ConfigMap `team-a-config` (greeting `hello from team-a`) exists in `team-a`.
- `team-a-apps` uses a `GitRepository` in `team-a` and `serviceAccountName: team-a`.
- The ServiceAccount `team-a` cannot create namespaces or read Secrets in `flux-system`.
