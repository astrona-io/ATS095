# Prerequisites

Before starting this lab you should be able to:

- Read the status conditions of a `GitRepository` with `kubectl describe` and `flux get`.
- Use `flux events`, `flux reconcile` and `kubectl patch` or `kubectl edit`.
- Tell a missing Secret from a wrong password, and a missing branch from a wrong address.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). It has one branch, `main`. `http://gitea.localtest.me:3000` works inside the cluster.
- The Secret `fleet-auth` with the working credentials, the `GitRepository` `fleet`, and the Flux `Kustomization` `podinfo`. `fleet` is not `Ready`.

## Working rules

- Everything is graded on the **final state**, so check `flux get sources git` at the end and leave the fix in place.
- Read the status before you change anything, and change one thing at a time. A second change made before you check the first makes it impossible to know which one worked.
- Keep the names `fleet`, `podinfo` and `fleet-auth`. Do not create a second `GitRepository` or a second Secret.
