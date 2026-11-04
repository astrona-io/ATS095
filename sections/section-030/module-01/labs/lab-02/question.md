# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Helm sources

## Scenario

The `fleet` team added the podinfo chart to the cluster. They created a `HelmRepository` and a `HelmChart`, both named `podinfo`, in `flux-system`. The `HelmRepository` works. The `HelmChart` has never resolved a version, and when the team fixed the first problem a second one appeared.

```sh
flux get sources helm
flux get sources chart
```

The podinfo chart is published at `https://stefanprodan.github.io/podinfo`. The newest line of the chart that the team supports is 6.x. The cluster has outbound internet.

## Your task

1. Read the `Ready` condition and the events of the `HelmChart` `podinfo` and find every reason it does not resolve.
2. Fix each fault in the `HelmChart` so that it resolves the newest 6.x chart.

## Constraints

- Fix the `HelmChart` `podinfo` in place. Do not delete and recreate it, and do not create another `HelmChart`.
- Do not change the `HelmRepository` `podinfo`. It works.
- Keep the source of the `HelmChart` as the `HelmRepository` `podinfo`.

## Done when

- The `HelmChart` `podinfo` is `Ready` on a 6.x chart version.
- The `HelmChart` fetches the chart `podinfo` from the `HelmRepository` `podinfo`.
- The `HelmRepository` `podinfo` is unchanged and `Ready`.
