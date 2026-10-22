# Overview: Fetch Helm Charts With source-controller (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Flux, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH and the Flux controllers in `flux-system`. source-controller fetches Helm sources; helm-controller installs `HelmRelease`s.
- An empty namespace `podinfo`. No Helm source exists yet.
- **Outbound internet** is needed. The podinfo chart is published at `https://stefanprodan.github.io/podinfo` (an HTTP Helm repository) and `oci://ghcr.io/stefanprodan/charts` (an OCI registry).

## Helpers

Paste these once in each new terminal. `show_helm_sources` prints every Helm source with its status. `list_charts` prints every `HelmChart` with its chart, source and resolved version, including the ones helm-controller creates for `HelmRelease`s.

```sh
show_helm_sources() {
  flux get sources helm
  flux get sources chart -A
}
list_charts() {
  kubectl get helmcharts -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,CHART:.spec.chart,SOURCE:.spec.sourceRef.name,VERSION:.status.artifact.revision
}
```

Use them like this: `show_helm_sources`, `list_charts`.

## Practice tasks

- Create a `HelmRepository` with `type: oci` and an `https://` address, then a `HelmChart` that uses it. Read the error with `flux events --for HelmChart/<name>`.
- Set a `HelmChart` version to `7.x` and read why it does not resolve. Set it back to `6.x`.
- Leave out `version` on a `HelmChart` and compare its revision with `6.x`.
- Create a `HelmRelease` for podinfo, then change `spec.chart.spec.version` in it and watch `list_charts` show the `HelmChart` change.
- Edit the `HelmChart` that a `HelmRelease` created and watch helm-controller set it back.
