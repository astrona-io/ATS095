# Who Reads The Artifact

An artifact is read by the controllers that apply it. This part follows the file to its readers.

## The consumers

| Reader | What it does with the artifact |
| --- | --- |
| kustomize-controller | Downloads the artifact of the `sourceRef` of a Flux `Kustomization`, unpacks it, runs `kustomize build` on `spec.path` and applies the result |
| helm-controller | Reads the chart artifact made by a `HelmChart` and installs or upgrades the release |
| notification-controller | Does not read artifacts; it receives the events that mention them |

The consumer checks the digest of what it downloaded against the digest in the status of the source, then unpacks the archive in memory or in a temporary folder. It records the revision it applied in its own status, for example `status.lastAppliedRevision` on a Flux `Kustomization`.

<!-- astrona:playground:renew -->

```sh
flux get kustomizations
kubectl -n flux-system get kustomization podinfo -o jsonpath='{.status.lastAppliedRevision}{"\n"}'
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.revision}{"\n"}'
```

When the two revisions are equal, the consumer applied the newest artifact. When they differ, the consumer has not caught up yet, or it failed; read its conditions.

## Follow the chain with flux trace

`flux trace` walks from a workload back to its source and prints the revision at every step:

```sh
flux trace deployment podinfo -n podinfo
```

## Why other namespaces cannot read it

The artifact server has no login: whoever can reach the URL can download the file. The protection is the network. The Flux network policies in `flux-system` allow ingress from pods in the same namespace, and (for metrics and webhooks) from specific places. Application pods in other namespaces are blocked. Treat this as a reason to keep secrets out of Git even when the repository is private: the artifact holds your manifests as plain files.

To read an artifact by hand you therefore need a pod in `flux-system`, as in the previous part. Do not weaken the policies to make debugging easier; start a short-lived pod instead and delete it afterwards.

## Common pitfalls

- Looking for the artifact in the namespace of the Flux `Kustomization`. The artifact belongs to the namespace of the source.
- Treating the artifact URL as private. It has no authentication; the network policy is the guard.
- Debugging a consumer by reading Git. The consumer sees only the artifact, so read the artifact.
