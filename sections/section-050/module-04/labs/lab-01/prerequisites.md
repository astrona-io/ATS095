# Prerequisites

Before starting this lab you should be able to:

- Create a source and a Kustomization in a namespace.
- Say what `serviceAccountName` on a Kustomization does.
- Use `kubectl auth can-i --as`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). `gitea.localtest.me:3000` works inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222` runs.
- A `tester` pod in the namespace `gitea` with `curl` and `jq`.
- The starting objects the question describes.

## Working rules

- Everything is graded on the **final state**, so check `flux get` at the end and leave the fix in place.
- Change one thing at a time and check again. Several causes mean several fixes, and the next error only appears after the first is gone.
