# Layers, semverFilter And Ignore Rules

A semver range looks at every tag in the repository, and an artifact can hold more than the files you want. This part narrows both: `semverFilter` limits which tags a range sees, `layerSelector` picks one layer of an artifact, and `ignore` removes files from what source-controller stores.

## Filter the tags first

Teams often push tags that are not releases, such as `build-481` or `1.3.0-rc.1`. `spec.ref.semverFilter` is a regular expression that source-controller applies to the tags before it applies the semver range. It works only when `spec.ref.semver` is set. A range that allows pre-releases plus a filter for release candidates follows the newest release candidate:

<!-- astrona:playground:renew -->

```sh
COMMIT="$(git ls-remote http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git refs/heads/main | cut -f1)"
rm -rf /tmp/rc && mkdir /tmp/rc && git clone -q http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git /tmp/rc/fleet
flux push artifact oci://registry.localtest.me:5001/podinfo-manifests:1.2.0-rc.1 \
  --path=/tmp/rc/fleet/apps/podinfo --source="http://gitea.localtest.me:3000/gitops/fleet.git" \
  --revision="main@sha1:$COMMIT" --insecure-registry
```

Now follow only release candidates:

```sh
kubectl -n flux-system patch ocirepository podinfo --type=merge -p '{"spec":{"ref":{"tag":null,"semver":">=1.0.0-0","semverFilter":".*-rc.*"}}}'
flux reconcile source oci podinfo
flux get sources oci
```

The revision is `1.2.0-rc.1@sha256:` and the digest. Without the filter, the range `>=1.0.0-0` would also match the stable tags and pick the highest of all. The filter is a regular expression, not a glob, so `.*-rc.*` and not `*-rc*`. Remove it again:

```sh
kubectl -n flux-system patch ocirepository podinfo --type=merge -p '{"spec":{"ref":{"semver":">=1.0.0 <2.0.0","semverFilter":null}}}'
flux reconcile source oci podinfo
```

## Pick a layer

A Flux artifact has one content layer, so you rarely need to choose. Other OCI artifacts, such as a Helm chart, have a different layer. `spec.layerSelector` has two fields. `mediaType` names the layer to take. `operation` is `extract` by default, which unpacks the layer into the artifact, or `copy`, which stores the layer as it is. Read what source-controller recorded:

```sh
kubectl -n flux-system get ocirepository podinfo -o jsonpath='{.status.observedLayerSelector}{"\n"}'
```

Without a selector, the field is empty and the first layer is taken. To set the selector for a Flux artifact, use its media type:

```yaml
spec:
  layerSelector:
    mediaType: application/vnd.cncf.flux.content.v1.tar+gzip
    operation: extract
```

With `operation: copy`, the artifact is the compressed archive itself, which a Flux `Kustomization` cannot read. Use `copy` only for consumers that expect the original layer, for example a `HelmChart` that reads a chart pushed as an OCI artifact.

## Ignore files

`spec.ignore` takes `.gitignore` rules and removes files from the artifact, the same way as for a `GitRepository`. The status field `observedIgnore` shows the rules that built the current artifact. Leave out a file that should not reach the cluster:

```sh
kubectl -n flux-system patch ocirepository podinfo --type=merge -p '{"spec":{"ignore":"service.yaml\n"}}'
flux reconcile source oci podinfo
flux reconcile kustomization podinfo --with-source
kubectl -n podinfo get svc
```

The Flux `Kustomization` prunes the Service, because its file is no longer in the artifact. Remove the rule to get it back:

```sh
kubectl -n flux-system patch ocirepository podinfo --type=merge -p '{"spec":{"ignore":null}}'
flux reconcile kustomization podinfo --with-source
```

```mermaid
flowchart LR
    T["registry tags"] -->|"semverFilter"| F["filtered tags"]
    F -->|"semver range"| R["one release"]
    R -->|"layerSelector"| L["one layer"]
    L -->|"ignore"| A["artifact"]
```

The diagram shows the order: filter the tags, pick a release, pick a layer, then remove files.

You can now choose which tags, which layer and which files a source takes. That finishes the source side. Signature checks with `spec.verify` build on the same status fields and are covered with the registry credentials in the next module.

## Common pitfalls

> [!WARNING]
> - **Using `semverFilter` without `semver`.** It is ignored.
> - **A glob in place of a regular expression.** `*-rc*` is not valid; write `.*-rc.*`.
> - **Using `operation: copy` for manifests.** The Flux `Kustomization` needs the extracted files.
> - **Pruning by accident.** An `ignore` rule that matches an applied file makes the Flux `Kustomization` delete the object.
