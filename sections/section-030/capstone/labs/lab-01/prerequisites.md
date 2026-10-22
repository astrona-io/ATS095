# Prerequisites

Before starting this lab you should be able to:

- Read a `HelmRelease`, a `HelmChart` and a `HelmRepository` and say how they connect.
- Use `flux get`, `flux events` and `flux reconcile helmrelease --with-source`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Outbound internet from the cluster**: the podinfo chart comes from `https://stefanprodan.github.io/podinfo`.
- The `HelmRepository` `podinfo` and the `HelmRelease` `podinfo` in `flux-system`, prepared as the task describes.

## Working rules

- Everything is graded on the **final state**, so check `flux get` at the end and leave the fix in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- Fix the objects in place. Do not delete and recreate them.
