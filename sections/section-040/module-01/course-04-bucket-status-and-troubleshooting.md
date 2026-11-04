# Bucket Status And Troubleshooting

When a `Bucket` does not become Ready, the cause is almost always one of four things: the Secret, the endpoint, the bucket name or the network. The status of the object tells you which one. This part reads the conditions, causes each failure on purpose in the playground and fixes it.

## Read the conditions

A `Bucket` reports its state in `status.conditions`. The ones to know:

| Condition | Meaning |
| --- | --- |
| `Ready` | `True` when an artifact is stored and the last fetch worked |
| `Reconciling` | `True` while a fetch or a new revision is in progress |
| `FetchFailed` | `True` when the server could not be read; the reason and message say why |
| `ArtifactInStorage` | `True` when the current artifact is stored in source-controller |
| `ArtifactOutdated` | `True` when a newer revision exists and is being fetched |

Print them in one line each:

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system get bucket podinfo -o jsonpath='{range .status.conditions[*]}{.type}{"\t"}{.status}{"\t"}{.reason}{"\t"}{.message}{"\n"}{end}'
flux events --for Bucket/podinfo
```

For a healthy source, `Ready` and `ArtifactInStorage` are `True`. Also read `status.observedGeneration`: when it is lower than `metadata.generation`, the controller has not seen your last edit yet. Look at the events, too: `flux events` shows each reconcile with its message in time order.

## Fault 1: wrong credentials

Break the Secret by writing a wrong secret key, and request a fetch:

```sh
kubectl -n flux-system patch secret s3-credentials --type=merge -p '{"stringData":{"secretkey":"wrong"}}'
kubectl -n flux-system annotate --overwrite bucket/podinfo reconcile.fluxcd.io/requestedAt="$(date +%s)"
sleep 10
kubectl -n flux-system get bucket podinfo -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

`Ready` becomes `False`, and `FetchFailed` carries the server's answer to the failed request. The message names the bucket and the error returned by the server, which is a signature or access error. A Secret that does not exist, or lacks the keys, ends in an authentication reason. Restore the key:

```sh
kubectl -n flux-system patch secret s3-credentials --type=merge -p '{"stringData":{"secretkey":"flux-s3-secret"}}'
flux reconcile source bucket podinfo
```

The artifact from before the failure stays in storage while the source is not Ready. The Flux `Kustomization` keeps what it applied, and it does not apply anything new until the source is Ready again.

## Fault 2: wrong bucket name or endpoint

A bucket name that does not exist gives a `FetchFailed` with a message that the bucket does not exist or cannot be read. A wrong endpoint gives a connection error: no such host, connection refused or a timeout. The message is the quickest way to tell the two apart:

```sh
kubectl -n flux-system patch bucket podinfo --type=merge -p '{"spec":{"bucketName":"podinfo-typo"}}'
sleep 10
kubectl -n flux-system get bucket podinfo -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
kubectl -n flux-system patch bucket podinfo --type=merge -p '{"spec":{"bucketName":"podinfo"}}'
```

Fixing the field starts a new reconciliation at once, because a change to the object triggers one.

## Fault 3: plain HTTP without `insecure`

```sh
kubectl -n flux-system patch bucket podinfo --type=merge -p '{"spec":{"insecure":false}}'
sleep 10
kubectl -n flux-system get bucket podinfo -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
kubectl -n flux-system patch bucket podinfo --type=merge -p '{"spec":{"insecure":true}}'
```

The source speaks TLS to a server that answers plain HTTP, so the request fails during the handshake. Many people read this as a network problem. The tell is that other settings are right and only `insecure` is missing.

## Timeouts and suspension

`spec.timeout` limits one fetch and defaults to 60 seconds. For a large bucket on a slow link, a timeout in the message of `FetchFailed` means that the fetch needs more time, not that the server is down. `spec.suspend: true` stops reconciliation completely. The object keeps its last artifact, and `flux get sources bucket` shows `SUSPENDED` as `True`. If a source seems frozen, check that field before you look anywhere else. `flux suspend source bucket podinfo` and `flux resume source bucket podinfo` set and clear it.

## A checklist

1. `flux get sources bucket`: is `READY` true, and is the revision what you expect?
2. `kubectl describe bucket`: read `FetchFailed`, its reason and its message.
3. Compare the endpoint, bucket and `insecure` with what the server needs.
4. Check the Secret keys, exactly `accesskey` and `secretkey` for the generic provider.
5. Check `prefix` and `ignore` if the source is Ready but the files are missing.
6. Check the Flux `Kustomization` path if the source is fine and nothing is applied.

## Common pitfalls

> [!WARNING]
> - **Fixing the Flux `Kustomization` when the source is broken.** If `Ready` of the Bucket is `False`, nothing downstream changes until you fix the source.
> - **Reading only the first line of a message.** The useful part, a host name or a status code, is often at the end.
> - **Forgetting the typo in the Secret name.** A missing Secret and a wrong password look alike. Check both.
> - **Leaving a source suspended.** A suspended source never fails; it just stops.
