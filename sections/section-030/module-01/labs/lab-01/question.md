# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Helm sources

## Scenario

A team wants the podinfo chart available in the cluster, ready for a `HelmRelease` they will add next week. They created a `HelmRepository` and a `HelmChart`, both named `podinfo`, in `flux-system`. The `HelmChart` has never resolved a version.

```sh
flux get sources helm
flux get sources chart
```

The podinfo chart is published in two places, and either one is fine for this team:

| Address | What it is |
| --- | --- |
| `https://stefanprodan.github.io/podinfo` | An HTTP Helm repository with an `index.yaml` |
| `oci://ghcr.io/stefanprodan/charts` | An OCI registry |

The cluster has outbound internet.

## Your task

1. Find out why the `HelmChart` `podinfo` does not resolve.
2. Fix the `HelmRepository` `podinfo` so that the `HelmChart` resolves the newest 6.x chart.

## Constraints

- Keep the `HelmChart` `podinfo` as it is: the chart `podinfo`, the range `6.x`, and the source `podinfo`.
- Fix the `HelmRepository` `podinfo` in place. Do not delete and recreate either object, and do not create another `HelmRepository`.

## Done when

- The `HelmChart` `podinfo` is `Ready` on a 6.x chart version.
- The type of the `HelmRepository` `podinfo` matches its address.
