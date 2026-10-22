# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Helm sources

## Scenario

The `HelmRelease` `podinfo` in `flux-system` should install the podinfo chart into the namespace `podinfo`. The team copied its YAML from an old wiki page, together with the `HelmRepository` `podinfo`. podinfo is not installed, and the `HelmRelease` reports only the first problem it meets.

```sh
flux get helmreleases
flux get sources helm
kubectl -n podinfo get pods
```

The podinfo chart is published at `https://stefanprodan.github.io/podinfo`, and its current major version is 6. The cluster has outbound internet.

## Your task

1. Follow the chain from the `HelmRelease` to its `HelmChart` and to the `HelmRepository`, and find every fault.
2. Fix them so that the `HelmRelease` installs the newest 6.x podinfo chart.

## Constraints

- Fix the `HelmRelease` `podinfo` and the `HelmRepository` `podinfo` in place. Do not delete and recreate them, and do not create another `HelmRepository`.
- Install the chart through the `HelmRelease`. Do not use `helm install` or apply the chart's manifests yourself.

## Done when

- The `HelmRepository` `podinfo` points at `https://stefanprodan.github.io/podinfo` and is `Ready`.
- The `HelmChart` behind the release reads the chart `podinfo` from the `HelmRepository` `podinfo` and is `Ready` on a 6.x version.
- The `HelmRelease` `podinfo` is `Ready`, and the Deployment `podinfo` runs in the namespace `podinfo`.
