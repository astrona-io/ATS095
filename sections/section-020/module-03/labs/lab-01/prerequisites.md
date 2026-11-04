# Prerequisites

Before starting this lab you should be able to:

- Read an `OCIRepository` and say which artifact it follows.
- Use `flux push artifact`, `flux list artifacts`, `flux get` and `flux reconcile`.
- Clone a Git repository and run commands in it.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). `http://gitea.localtest.me:3000` and `gitea.localtest.me:2222` (SSH) work inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222` runs.
- **An OCI registry** over plain HTTP. `registry.localtest.me:5001` works inside the cluster, and on your machine while `kubectl -n registry port-forward svc/registry 5001:5001` runs.
- The `OCIRepository` `podinfo` and the Flux `Kustomization` `podinfo`, prepared as the task describes.

## Working rules

- Everything is graded on the **final state**, so check `flux get` at the end and leave the fix in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- Keep the names `podinfo` and the repository `podinfo-manifests`. Do not delete releases from the registry.
