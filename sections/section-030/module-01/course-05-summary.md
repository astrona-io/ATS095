# Summary

helm-controller installs charts, but source-controller fetches them. Two source objects sit between a `HelmRelease` and the chart server, and most "chart not found" problems live in one of them.

## What you learned

A `HelmRepository` says where charts live. With the default type, its address is `http://` or `https://`, and source-controller downloads the repository's `index.yaml` and stores an exact copy as the artifact, so it is `Ready` with a revision. With `type: oci`, the address is `oci://`, source-controller fetches nothing, and the object has no status at all: it only holds the address and the credentials. The type must match the address. The Flux documentation calls the `oci` type maintenance mode and recommends an `OCIRepository` for new OCI chart setups.

A `HelmChart` picks one chart at one version. It names the `chart`, a `version` or range (`*` when left out), a `sourceRef` and an `interval`. source-controller resolves the highest version inside the range, from the stored index or from the registry's tags, and stores the chart package as the artifact; the revision is the chart version. `reconcileStrategy` decides when a chart from Git or a bucket counts as new, and `valuesFiles` merges values files from the chart. A `Ready` `HelmChart` is also the only proof that an `oci` `HelmRepository` works.

When a `HelmChart` does not resolve, its `Ready` condition and its events carry the reason. A version range with no match, a chart name the repository does not publish and a broken source each produce a different message, and `Stalled` is set only for an invalid reference. The `flux` tool creates a `HelmRepository`, reconciles, suspends, resumes, exports and deletes Helm sources, but has no command to create a `HelmChart`.

A `HelmRelease` describes its chart in `spec.chart.spec`, and helm-controller creates the matching `HelmChart`. To fix a chart problem, follow the chain back: the `HelmRelease`, its `HelmChart`, then the `HelmRepository`, and change the `HelmRelease` rather than the `HelmChart` it created. The key facts to remember are these:

- The revision of a `HelmChart` is the resolved chart version.
- An empty status on an `oci` `HelmRepository` is normal.
- A version range with no match leaves the `HelmChart` not ready.
- Read the message of the `Ready` condition before changing a field.
- `flux reconcile source chart --with-source` refreshes the repository first.
- helm-controller rewrites the `HelmChart` it created from the `HelmRelease`.

<!-- astrona:playground:destroy -->
