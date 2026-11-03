# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Git sources and authentication

## Scenario

The `GitRepository` `fleet` in the namespace `flux-system` was moved to SSH last week and has not fetched since. The deploy key in the Secret `fleet-ssh` is already registered in Gitea as a read-only deploy key of `gitops/fleet`, and the key is correct. The Flux `Kustomization` `podinfo` waits for the source and applies nothing.

Start by reading the state:

```sh
flux get sources git
kubectl -n flux-system describe gitrepository fleet
```

For commands that call Gitea from your machine, start the port-forward in a second terminal first, and leave it running. If `gitea.localtest.me` does not resolve on your machine, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

## Your task

1. Find from the conditions and events of `fleet` why it cannot fetch. There is more than one cause.
2. Fix each cause without creating a new key pair and without registering a new deploy key.
3. Confirm that the Flux `Kustomization` `podinfo` applies the revision of `fleet`.

## Constraints

- Keep the names `fleet`, `fleet-ssh` and `podinfo`. Do not create a second `GitRepository` or a second Secret.
- Do not change the key pair (`identity` and `identity.pub`) in `fleet-ssh`.
- Do not switch `fleet` to HTTP and do not disable host key checking. The `known_hosts` key must hold the real host key of the Gitea SSH server.
- Do not change anything in the repository itself.

## Done when

- `flux get sources git` shows `fleet` as `Ready` on a `main@sha1:` revision, fetched from `ssh://git@gitea.localtest.me:2222/gitops/fleet.git` with the Secret `fleet-ssh`.
- `known_hosts` in `fleet-ssh` has an entry for `[gitea.localtest.me]:2222` with a real host key of the Gitea server.
- `fleet-ssh` still holds the registered read-only deploy key and no password.
- The Flux `Kustomization` `podinfo` is `Ready` on the same revision, and `podinfo` runs 2 ready replicas.
