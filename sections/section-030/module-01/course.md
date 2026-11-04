# Fetch Helm Charts With source-controller

A `HelmRelease` names a chart and a version range, and helm-controller installs it. When the release fails because the chart cannot be found, the error is several objects away from the cause. helm-controller does not download charts itself: it asks source-controller, through a `HelmChart`, which in turn reads a `HelmRepository`.

A **Helm chart** is a package of Kubernetes templates and default values that Helm turns into manifests. A **`HelmRepository`** is the Flux object that tells source-controller where a set of charts lives: an HTTP server with an `index.yaml` file, or an OCI registry. A **`HelmChart`** is the Flux object that picks one chart from a source, at one version or the newest version in a range, and stores it as an artifact.

Keep one sentence in mind: **the revision of a `HelmChart` is the chart version it resolved.** If that version is not what you expect, look at the range in the `HelmChart` and at the repository it reads.

The module has four parts. **HTTP And OCI Helm Repositories** creates both types of `HelmRepository` for the same chart and compares what source-controller does with each. **HelmChart Objects And Chart Versions** resolves version ranges with a `HelmChart`, then lets a `HelmRelease` create its own `HelmChart`. A graded lab follows it. **HelmChart Status, Conditions And Events** reads why a chart does not resolve, and a second graded lab follows. **Managing Helm Sources With The Flux CLI** creates, refreshes, pauses and exports Helm sources from the terminal.

## Learning objectives

After this module you can:

- Create a `HelmRepository` of type `default` and one of type `oci`, and explain why only the first reports a status.
- Say what source-controller stores for an HTTP chart repository.
- Write a `HelmChart` with a version range and read the chart version it resolved.
- Explain `reconcileStrategy` and `valuesFiles`.
- Find the `HelmChart` that helm-controller creates for a `HelmRelease`.
- Match the type of a `HelmRepository` to its address.
- Read the conditions and events of a `HelmChart` to find a wrong version range or chart name.
- Create, reconcile, suspend, resume and export Helm sources with the `flux` tool.

## Before you start

You need Kubernetes basics, and you should know what Helm does: it installs a chart as a release, with values that fill in the chart's templates. You do not need the `helm` command-line tool; Flux does that work in the cluster.

Your playground is a single-node `kind` cluster with **Flux v2.9.6**, the `flux` command-line tool and an empty namespace `podinfo`. No Helm source exists yet. The cluster needs **outbound internet** for this module: the chart comes from these two public addresses, which serve the same podinfo chart:

| Address | Type |
| --- | --- |
| `https://stefanprodan.github.io/podinfo` | HTTP Helm repository with an `index.yaml` |
| `oci://ghcr.io/stefanprodan/charts` | OCI registry with the chart `podinfo` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
