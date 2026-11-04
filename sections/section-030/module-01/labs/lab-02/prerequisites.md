# Prerequisites

Before starting this lab you should be able to:

- Read the conditions of a `HelmChart` and its events with `flux events`.
- Patch a field of an object with `kubectl patch`.
- Reconcile a source with `flux reconcile source chart`.

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Outbound internet from the cluster**: the podinfo chart comes from `https://stefanprodan.github.io/podinfo`.
- The `HelmRepository` `podinfo` and the `HelmChart` `podinfo` in `flux-system`, prepared as the task describes.

## Working rules

- Everything is graded on the **final state**, so check `flux get` at the end and leave the fix in place.
- Change one field at a time and check again. The second fault only shows after the first is fixed.
- Fix the objects in place. Do not delete and recreate them.
