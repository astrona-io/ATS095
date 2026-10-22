# Section 030: HelmRepository And HelmChart

Most software you install on Kubernetes comes as a Helm chart: a package of templates plus default values. Flux installs charts through `HelmRelease` objects, but before helm-controller can install anything, source-controller must fetch the chart. Two source objects do that work: a `HelmRepository` says where the charts live, and a `HelmChart` says which chart, at which version. When a `HelmRelease` fails with "chart not found", the cause is almost always in one of these two.

This section works with both kinds of chart repository, the classic HTTP repository with an `index.yaml` and the OCI registry, and shows how a `HelmChart` turns a version range into one exact chart version.

**Topic covered:** Helm sources

## What you will learn

- The two types of `HelmRepository`, `default` and `oci`, and why an `oci` repository has no status.
- What source-controller stores for an HTTP repository: a copy of its `index.yaml`.
- The fields of a `HelmChart`: `chart`, `version`, `sourceRef`, `reconcileStrategy` and `valuesFiles`.
- How a version range resolves to one chart version, and how that version becomes the revision.
- How helm-controller creates a `HelmChart` for every `HelmRelease`, and how to find it.

## The learning path

The module has a landing page, two parts, a graded lab right after the part it tests, and a summary. The landing page also starts the module's playground. This section needs outbound internet from the cluster: the podinfo chart comes from `https://stefanprodan.github.io/podinfo` and `oci://ghcr.io/stefanprodan/charts`.

### 1. Fetch Helm Charts With source-controller

The playground holds the Flux controllers and an empty namespace `podinfo`. You create every Helm source yourself.

1. HTTP And OCI Helm Repositories
2. HelmChart Objects And Chart Versions, followed by the lab **Make A Helm Chart Resolve**
3. Summary

## Section capstone: Make A HelmRelease's Chart Resolve

The capstone is one graded scenario with several faults along the chain from `HelmRelease` to `HelmChart` to `HelmRepository`. podinfo is not installed, and the error on the `HelmRelease` only names the first fault. You follow the chain back, fix each object in place, and prove that podinfo runs. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-095-capstone-030
```
