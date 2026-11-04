# Prerequisites

Before starting this lab you should be able to:

- Read the conditions and events of a `GitRepository` and a `HelmChart`.
- Say what `chart` means for a `HelmChart` that reads from Git.
- Explain `reconcileStrategy`.

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Outbound internet from the cluster**: the Git repository is `https://github.com/stefanprodan/podinfo`.
- The `GitRepository` and the `HelmChart` named `podinfo-git` in `flux-system`.

## Working rules

- Everything is graded on the **final state**, so check `flux get` at the end and leave the fix in place.
- Fix the source before the chart, and check after each change.
- Fix the objects in place. Do not delete and recreate them.
