# HTTP And OCI Helm Repositories

Helm charts are published in two ways. The older way is an HTTP server that serves an `index.yaml` file, a list of every chart and version it holds. The newer way is an OCI registry, where each chart version is an artifact with a tag. Flux supports both through the `HelmRepository` object, but it treats them very differently. This part creates one of each for the same podinfo chart and shows what source-controller does, and does not do, with them.

## An HTTP Helm repository

A `HelmRepository` of the default type points at an HTTP or HTTPS address. Save this as `helmrepository-podinfo.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 10m
  url: https://stefanprodan.github.io/podinfo
```

Apply it:

```sh
kubectl apply -f helmrepository-podinfo.yaml
```

Then check the result:

```sh
flux get sources helm
```

The row for `podinfo` shows `READY` as `True` and a revision. source-controller downloaded the `index.yaml` of the repository and stored an exact copy as the artifact, named `index-` followed by the revision and `.yaml`. That index lists every chart version the repository holds, so later, when a `HelmChart` asks for a version range, source-controller can answer from its stored copy. `interval: 10m` is how often it downloads the index again to see new versions; without the field, the interval is `1m`.

## An OCI Helm repository

Now point a second `HelmRepository` at the OCI registry that holds the same chart. The field `type: oci` says that the address is a registry, not an HTTP index. Save this as `helmrepository-podinfo-oci.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: podinfo-oci
  namespace: flux-system
spec:
  type: oci
  interval: 10m
  url: oci://ghcr.io/stefanprodan/charts
```

Apply it:

```sh
kubectl apply -f helmrepository-podinfo-oci.yaml
```

Then check the result:

```sh
flux get sources helm
```

The row for `podinfo-oci` has an empty `READY` and an empty `STATUS`, and that is correct. An OCI registry has no `index.yaml` to download, so source-controller fetches nothing for this object. An `oci` `HelmRepository` is only a container for the address and, if needed, the credentials; its existence is all a `HelmChart` needs. The `interval` is ignored for this type.

## The two types side by side

The difference matters most when something goes wrong. A broken HTTP repository shows `False` and a reason in `flux get sources helm`. A broken OCI repository shows nothing until a `HelmChart` tries to use it.

| | `type: default` | `type: oci` |
| --- | --- | --- |
| Address | `http://` or `https://` | `oci://` |
| What source-controller fetches | The `index.yaml`, stored as an artifact | Nothing |
| Status | `Ready` with a revision | Empty |
| Credentials | Secret with `username` and `password` | Secret with `username` and `password`, or a Docker config Secret |
| Plain HTTP | Allowed by the address itself | Needs `insecure: true` |

The type and the address must match. A `default` repository with an `oci://` address, or an `oci` repository with an `https://` address, gives you a source that never works.

The Flux documentation also says that the `oci` type is in maintenance mode. For new setups with OCI charts, it recommends an `OCIRepository` with a `layerSelector` for the Helm chart media type, which a `HelmRelease` can reference directly. The `oci` `HelmRepository` still works and is common in existing clusters, so you need to read it.

You can now create both types of chart repository, and you know why one reports a status and the other does not. The open question is how one chart at one version comes out of a repository, which is the job of the `HelmChart`.

## Common pitfalls

> [!WARNING]
> - **A type that does not match the address.** `oci://` needs `type: oci`; `https://` needs the default type.
> - **Reading an empty status as a failure.** An `oci` `HelmRepository` never reports `Ready`. Check the `HelmChart` that uses it instead.
> - **Expecting the `interval` of an `oci` repository to do something.** It is ignored; the `HelmChart` has its own interval.
> - **Forgetting the cluster needs internet.** source-controller downloads the index and the charts from the public addresses.
