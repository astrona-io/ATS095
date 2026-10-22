# Prerequisites

Before starting this lab you should be able to:

- Read a `GitRepository` and say how it authenticates to Git.
- Use `flux create secret git`, `flux get` and `flux reconcile`.
- Call an HTTP API with `curl`, or use the Gitea web page.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). `http://gitea.localtest.me:3000` and `gitea.localtest.me:2222` (SSH) work inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222` runs.
- The `GitRepository` `fleet` and the Flux `Kustomization` `podinfo`, working, with the password Secret `fleet-auth`.

## Working rules

- Everything is graded on the **final state**, so check `flux get` at the end and leave the fix in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- Keep the names `fleet`, `podinfo` and `fleet-ssh`. Do not create a second `GitRepository`.
