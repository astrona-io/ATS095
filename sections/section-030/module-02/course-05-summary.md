# Summary

Charts come from more places than a public repository, and each place needs its own fields. Credentials live in Secrets that the source object names, and a wrong Secret name or key shows up as an error before the first request is made.

## What you learned

An HTTP `HelmRepository` takes basic authentication from a Secret with the keys `username` and `password` in `spec.secretRef`. It sends the credentials only to the host in `spec.url`, unless `spec.passCredentials` is true. A client certificate goes in `spec.certSecretRef`, a Secret with `tls.crt`, `tls.key` and an optional `ca.crt`. TLS data in `secretRef` is deprecated.

An OCI `HelmRepository` uses a Secret of type `kubernetes.io/dockerconfigjson`, which `flux create secret oci` creates. Its `provider` field is `generic`, `aws`, `azure` or `gcp` and applies to OCI only. An `oci` repository has no status, so a wrong password shows up on the `HelmChart` that uses it. The Flux documentation recommends an `OCIRepository` for new OCI chart setups.

A `HelmChart` can also be built from a `GitRepository` or a `Bucket`. Then `chart` is a path, `version` is ignored and the chart version is read from `Chart.yaml`. `reconcileStrategy: Revision` rebuilds the chart on every new source revision, `valuesFiles` merges values files in order, and `ignoreMissingValuesFiles` skips files that do not exist. Verification with `spec.verify` uses cosign or notation, works for OCI sources only, and sets the condition `SourceVerified`. The key facts to remember are these:

- Secrets must be in the namespace of the source object.
- `passCredentials` is off by default for a reason.
- For Git and Bucket sources, `chart` is a path.
- `Revision` rebuilds on each commit; `ChartVersion` only when the version changes.
- `matchOIDCIdentity` is for cosign keyless verification.

<!-- astrona:playground:destroy -->
