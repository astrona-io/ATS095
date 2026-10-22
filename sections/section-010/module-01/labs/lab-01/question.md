# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Git sources and authentication

## Scenario

The cluster reads the repository `gitops/fleet` through the `GitRepository` `fleet` in the namespace `flux-system`. It signs in with the Secret `fleet-auth`, which holds the password of the Gitea administrator `gitops`. A security review flagged it: a leaked copy of that Secret could change or delete every repository on the server.

Everything works today, and it must keep working while you change it:

```sh
flux get sources git
flux get kustomizations
```

Start the port-forward in a second terminal first, and leave it running. If `gitea.localtest.me` does not resolve on your machine, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

## Your task

1. Create a Secret named `fleet-ssh` in `flux-system` with an SSH key pair for Flux and the host key of `gitea.localtest.me:2222`.
2. Register the public key of `fleet-ssh` as a **read-only** deploy key of `gitops/fleet`.
3. Move the `GitRepository` `fleet` to `ssh://git@gitea.localtest.me:2222/gitops/fleet.git` with the Secret `fleet-ssh`.
4. Once Flux reads over SSH, delete the Secret `fleet-auth`.

## Constraints

- Keep the names `fleet` and `podinfo`. Do not create a second `GitRepository`.
- The deploy key must be read-only, and `fleet-ssh` must not hold a password.
- Do not change anything in the repository itself.
- `podinfo` must keep running from Git throughout.

## Done when

- `flux get sources git` shows `fleet` as `Ready` on a `main@sha1:` revision, fetched from the `ssh://` address with the Secret `fleet-ssh`.
- `fleet-ssh` holds an SSH identity and `known_hosts`, and `fleet-auth` no longer exists.
- The public key of `fleet-ssh` is a read-only deploy key of `gitops/fleet`.
- The Flux `Kustomization` `podinfo` is `Ready` on the same revision, and `podinfo` runs 2 ready replicas.
