# OCIRepository: Tags, Semver Ranges And Digests

The registry holds three releases of the podinfo manifests, and none of them is running. An `OCIRepository` tells source-controller which release to fetch: one fixed tag, the newest tag in a semver range, or one exact digest. This part connects the cluster to the registry, moves from a fixed tag to a range, and pins a digest to see which field wins.

## Fetch one fixed tag

The `url` of an `OCIRepository` is the `oci://` address of the repository in the registry, without a tag. The tag goes into `ref`. The registry uses plain HTTP, so `insecure: true` allows it; leave that field out for any real registry, which uses HTTPS. Save this as `ocirepository-podinfo.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 1m
  url: oci://registry.localtest.me:5001/podinfo-manifests
  insecure: true
  ref:
    tag: 1.0.0
```

Apply it:

```sh
kubectl apply -f ocirepository-podinfo.yaml
```

Then check the result:

```sh
flux get sources oci
```

The row for `podinfo` shows `READY` as `True` and a revision of the form `1.0.0@sha256:` followed by the digest. The part before the `@` is the tag, and the part after it is the content the tag pointed at when source-controller fetched it. Inside the cluster, `registry.localtest.me` already points at the registry Service, so source-controller does not need your port-forward.

## Apply it with a Flux Kustomization

The artifact holds the files of `apps/podinfo` at its root, so the Flux `Kustomization` reads the path `./`. Its `sourceRef` names the kind `OCIRepository`. Save this as `kustomization-podinfo.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 5m
  path: ./
  prune: true
  wait: true
  timeout: 2m
  sourceRef:
    kind: OCIRepository
    name: podinfo
```

Apply it:

```sh
kubectl apply -f kustomization-podinfo.yaml
```

Then check the result:

```sh
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

The Flux `Kustomization` is `Ready` on the same `1.0.0@sha256:` revision, and the Deployment runs 1 replica, the value in release `1.0.0`. The cluster now runs a release that it fetched from the registry, without reading Git at all.

## Follow a semver range

A fixed tag never changes, so new releases never arrive. A semver range follows them. source-controller lists the tags of the repository, keeps the ones that are valid versions inside the range, and fetches the highest. A pre-release such as `1.2.0-rc.1` does not match a plain range like `>=1.0.0 <2.0.0`; only a range that names a pre-release itself lets pre-releases in.

The fields of `ref` have an order: `digest` wins over `semver`, and `semver` wins over `tag`. Replace the whole `ref` with a range, so no old field stays behind:

```sh
kubectl -n flux-system patch ocirepository podinfo --type=json -p \
  '[{"op":"replace","path":"/spec/ref","value":{"semver":">=1.0.0 <2.0.0"}}]'
flux reconcile kustomization podinfo --with-source
flux get sources oci
kubectl -n podinfo get deployment podinfo
```

The revision moves to the highest 1.x release: `1.2.0@sha256:` if you pushed it, otherwise `1.1.0@sha256:`. The Deployment follows with 2 or 3 replicas. From now on, every `1.x` release you push reaches the cluster within the interval, and a `2.0.0` waits for a person to change the range.

## Pin a digest

A digest is the strongest pin there is: it names one exact content, and nobody can move it. Copy the digest from the current revision and set it as `ref.digest`, next to the range:

```sh
DIGEST="$(kubectl -n flux-system get ocirepository podinfo -o jsonpath='{.status.artifact.revision}' | sed 's/.*@//')"
kubectl -n flux-system patch ocirepository podinfo --type=merge -p "{\"spec\":{\"ref\":{\"digest\":\"$DIGEST\"}}}"
kubectl -n flux-system get ocirepository podinfo -o jsonpath='{.spec.ref}{"\n"}'
```

The `ref` now holds both `semver` and `digest`, and the digest wins: source-controller fetches exactly that content, whatever the range would pick. That is useful for a freeze before an audit and dangerous by accident, because new releases silently stop. Remove the digest again so the range decides:

```sh
kubectl -n flux-system patch ocirepository podinfo --type=json -p '[{"op":"remove","path":"/spec/ref/digest"}]'
```

## Two more fields worth knowing

An OCI artifact can hold more than one layer, for example a Helm chart. **`layerSelector`** picks one layer by its `mediaType`, and its `operation` says whether source-controller extracts it (`extract`, the default) or copies it as it is (`copy`). A Flux artifact has a single layer, so you do not need it here. **`verify`** makes source-controller check a signature before it uses an artifact: with `provider: cosign` and a Secret that holds the public key, an unsigned or wrongly signed release is refused. Signing belongs in the pipeline that pushes the release.

You can now point an `OCIRepository` at a registry, choose between a tag, a range and a digest, and apply the result with a Flux `Kustomization`. What remains is to follow a release line end to end: push a new version and watch the cluster take it.

## Common pitfalls

> [!WARNING]
> - **A tag in the `url`.** `oci://…/podinfo-manifests:1.1.0` is not a valid address for an `OCIRepository`. The tag goes into `ref`.
> - **A plain-HTTP registry without `insecure: true`.** source-controller tries HTTPS and fails. Use `insecure` only for a lab registry.
> - **An old `tag` or `digest` left next to a new `semver`.** A digest overrides the range. Replace the whole `ref` when you change strategy.
> - **The wrong `sourceRef.kind`.** A Flux `Kustomization` that names `GitRepository` looks for a source that does not exist. Use `OCIRepository`.
> - **Expecting a pre-release from a plain range.** `>=1.0.0 <2.0.0` skips `1.2.0-rc.1` on purpose.

## Your mission: Follow The Newest 1.x Release From A Registry

You can now make an `OCIRepository` follow a release line and push releases into it. The graded lab gives you a cluster fixed to release `1.0.0` of a registry that also holds a newer 1.x release, a pre-release and a `2.0.0`, and asks you to follow the newest stable 1.x release, push a new one from Git, and prove that the cluster takes it.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-095-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-095-lab-020-01
astrona start ats-095-playground-020-01
```
