# Summary

A container registry can hold Kubernetes manifests as well as images. Flux packs a folder into an OCI artifact, pushes it under a tag, and lets each cluster pull the release it should run.

## What you learned

`flux push artifact` turns one folder into an OCI artifact and pushes it to a registry under a tag. The artifact has one layer with the media type `application/vnd.cncf.flux.content.v1.tar+gzip`, a config with `application/vnd.cncf.flux.config.v1+json`, and annotations that record the Git source and revision from `--source` and `--revision`. `flux list artifacts` lists the tags of a repository with their digests and annotations. A tag is a movable name; the digest, the `sha256` hash of the manifest, names one exact content and never changes.

An `OCIRepository` tells source-controller which release to fetch. Its `url` is the `oci://` address of the repository without a tag, and `insecure: true` allows a registry that uses plain HTTP. In `ref`, a `tag` fixes one release, a `semver` range follows the highest valid version inside the range, and a `digest` pins exact content; `digest` wins over `semver`, which wins over `tag`. A plain range skips pre-releases such as `1.2.0-rc.1`. The revision has the form `<tag>@sha256:<digest>`. A Flux `Kustomization` reads the artifact through `sourceRef.kind: OCIRepository`, and because a Flux artifact holds the folder at its root, its path is `./`.

Reading the state is a skill of its own. The conditions `Ready`, `FetchFailed` and `ArtifactInStorage`, the events and the artifact metadata say why a source does not fetch, and a failed fetch keeps the last artifact, so the cluster stays on the old release. `semverFilter` limits the tags a range sees, `layerSelector` picks a layer with `extract` or `copy`, and `ignore` removes files from the artifact.

Two more fields complete the picture. `layerSelector` picks one layer by media type from artifacts with several layers, such as Helm charts, and `verify` with `provider: cosign` refuses releases without a valid signature. The key facts to remember are these:

- No tag in the `url` of an `OCIRepository`; the tag goes into `ref`.
- Replace the whole `ref` when you change strategy, because a leftover `digest` wins.
- Give every semver range an upper bound.
- Change one field at a time, and read the events after each change.
- `semverFilter` is a regular expression and works only with `semver`.
- Push every release with `--source` and `--revision`, so it links back to Git.

<!-- astrona:playground:destroy -->
