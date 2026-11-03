# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Git sources, status and troubleshooting

## Scenario

A platform engineer on the `outpost` team applied a `GitRepository` named `fleet` in the namespace `flux-system` and a Flux `Kustomization` named `podinfo` that reads it. Nothing is deployed. The namespace `podinfo` has no Deployment, and the `GitRepository` is not `Ready`.

The Git server holds the private repository `gitops/fleet` with one branch, `main`. The Secret `fleet-auth` holds the correct credentials for it. Nobody knows what the engineer got wrong, and the engineer is not available.

Start here:

```sh
flux get sources git
kubectl -n flux-system describe gitrepository fleet
```

## Your task

1. Read the status conditions and events of `fleet` and find every reason it cannot fetch the repository. There is more than one.
2. Fix the `GitRepository` object so that source-controller fetches `main` of `gitops/fleet` with the credentials in `fleet-auth`.
3. Ask Flux to reconcile and confirm that `fleet` and `podinfo` become `Ready`.

## Constraints

- Keep the names `fleet`, `podinfo` and `fleet-auth`. Do not create a second `GitRepository` or a second Secret.
- Do not change the address of the repository, and do not suspend `fleet`.
- Do not change anything in the repository itself. Do not create a branch in Gitea.
- Do not change `fleet-auth`.

## Done when

- `flux get sources git` shows `fleet` as `Ready` on a `main@sha1:` revision. The condition `ArtifactInStorage` is `True` and the condition `FetchFailed` is not `True`.
- `fleet` reads the Secret `fleet-auth` and follows the branch `main`.
- The Flux `Kustomization` `podinfo` is `Ready` on the same revision, and `podinfo` runs 2 ready replicas.
