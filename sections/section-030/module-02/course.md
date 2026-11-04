# Private Helm Repositories, Chart Sources And Chart Verification

Public charts are the easy case. In a company the charts sit behind a password, behind a client certificate, in a private registry or inside a Git repository next to the application code. source-controller can fetch from all of these, but each one needs a different field, and a wrong field produces an error that names a Secret or a path instead of the real cause.

A **Secret** is a Kubernetes object that holds sensitive data such as a password or a certificate. A **`HelmChart`** can read its chart from a `HelmRepository`, from a `GitRepository` or from a `Bucket`. **Chart verification** checks a cryptographic signature on a chart in an OCI registry before source-controller stores it.

Keep one sentence in mind: **credentials live in a Secret that the source object names, and the kind of source decides which keys the Secret needs.**

The module has four parts. **Credentials And TLS For HTTP Helm Repositories** covers basic authentication, `passCredentials` and client certificates. **Credentials For OCI Helm Repositories** covers registry Secrets and the cloud provider field. **Charts From Git And Bucket Sources** builds a chart from a Git repository and decides when it is rebuilt. A graded lab follows that part. **Verify Chart Signatures And Choose A Chart Source** covers `spec.verify` and compares the three kinds of chart source.

## Learning objectives

After this module you can:

- Write a Secret for basic authentication and a Secret for a client certificate, and attach each to a `HelmRepository`.
- Explain when `passCredentials` is needed and why it is off by default.
- Create a registry Secret with `flux create secret oci` and use it with an `oci` `HelmRepository`.
- Name the four values of `spec.provider` and say that they apply to OCI only.
- Build a `HelmChart` from a `GitRepository` and choose between `ChartVersion` and `Revision` for `reconcileStrategy`.
- Use `valuesFiles` and `ignoreMissingValuesFiles`.
- Say what `spec.verify` checks, and which sources support it.

## Before you start

You need the basics of Helm sources: a `HelmRepository`, a `HelmChart` and how they connect. Your playground is a single-node `kind` cluster with **Flux v2.9.6**, the `flux` command-line tool and an empty namespace `podinfo`. The cluster needs **outbound internet**: the exercises use the public podinfo chart repository and the public podinfo Git repository. Any username or password in this module is a lab-only value, and a real repository uses HTTPS and a secret you protect.

| Address | What it is |
| --- | --- |
| `https://stefanprodan.github.io/podinfo` | HTTP Helm repository with an `index.yaml` |
| `oci://ghcr.io/stefanprodan/charts` | OCI registry with the chart `podinfo` |
| `https://github.com/stefanprodan/podinfo` | Git repository that holds the chart in `charts/podinfo` on the branch `master` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
