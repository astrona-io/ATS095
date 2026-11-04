# Overview: Private Helm Repositories, Chart Sources And Chart Verification (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Flux, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH and the Flux controllers in `flux-system`. source-controller fetches Helm sources; helm-controller installs `HelmRelease`s.
- An empty namespace `podinfo`. No Helm source exists yet.
- **Outbound internet** is needed. The podinfo Git repository is `https://github.com/stefanprodan/podinfo`. The podinfo chart is published at `https://stefanprodan.github.io/podinfo` (an HTTP Helm repository) and `oci://ghcr.io/stefanprodan/charts` (an OCI registry).

## Helpers

Paste these once in each new terminal. `show_helm_sources` prints every Helm source with its status. `show_conditions` prints the conditions of one object, for example `show_conditions helmchart podinfo-git`.

```sh
show_helm_sources() {
  flux get sources helm
  flux get sources git
  flux get sources chart -A
}
show_conditions() {
  kubectl -n flux-system get "$1" "$2" -o jsonpath='{range .status.conditions[*]}{.type}{"\t"}{.status}{"\t"}{.reason}{"\n"}{end}'
}
```

## Practice tasks

- Create a `HelmRepository` with a `secretRef` to a Secret that does not exist, read the event, then create the Secret.
- Create a registry Secret with `flux create secret oci --export` and compare it with `kubectl create secret docker-registry --dry-run=client -o yaml`.
- Build a `HelmChart` from the public podinfo Git repository with `chart: ./charts/podinfo`, then switch `reconcileStrategy` to `Revision` and compare the revisions.
- Add a values file that does not exist to `valuesFiles`, read the error, then set `ignoreMissingValuesFiles: true`.
- Run `kubectl explain helmchart.spec.verify` and read every field.
