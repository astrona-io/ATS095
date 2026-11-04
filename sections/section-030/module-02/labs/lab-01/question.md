# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Helm sources

## Scenario

The `fleet` team keeps the chart of podinfo in the Git repository `https://github.com/stefanprodan/podinfo`, in the directory `charts/podinfo`. They created a `GitRepository` and a `HelmChart`, both named `podinfo-git`, in `flux-system`. Nothing is built.

```sh
flux get sources git
flux get sources chart
```

The team also has a rule: the chart author sometimes forgets to raise the version in `Chart.yaml`, and the cluster must still pick up every new commit of the chart.

## Your task

1. Find out why the `GitRepository` `podinfo-git` is not ready and fix it.
2. Find out why the `HelmChart` `podinfo-git` does not build and fix it.
3. Make the `HelmChart` produce a new chart artifact for every new commit, even when the chart version does not change.

## Constraints

- Fix both objects in place. Do not delete and recreate them, and do not create other objects.
- Keep the `HelmChart` reading from the `GitRepository` `podinfo-git`.

## Done when

- The `GitRepository` `podinfo-git` is `Ready` on the branch the repository really uses.
- The `HelmChart` `podinfo-git` is `Ready` and built from the chart directory.
- The chart revision of the `HelmChart` includes the source revision.
