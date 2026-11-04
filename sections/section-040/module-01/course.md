# Sync From A Bucket And Control When Flux Fetches

A build job writes the manifests for a cluster to a bucket on an S3-compatible object store. The cluster should apply them, and when the job writes a new version, the cluster should apply that too, without anyone running `kubectl`. Flux can read the bucket directly, and it decides on its own when to look again, unless you tell it to look now.

A **bucket** is a container for files, called objects, on an object store. S3 is the object storage API that Amazon introduced and that many other servers speak too; an **S3-compatible** server accepts the same requests. A **`Bucket`** is the Flux object that tells source-controller which bucket to read, on which server, with which credentials.

Keep one sentence in mind: **a source fetches at its interval, and a reconcile request makes it fetch now.** Everything about timing in Flux follows from that.

The module has four parts. **Bucket Sources On S3-Compatible Storage** connects a `Bucket` to the playground's bucket and applies its manifests with a Flux `Kustomization`. **Reconciliation Triggers, Artifacts And Garbage Collection** uploads a change, makes Flux take it without waiting, and reads the artifact source-controller stores. **Providers, Prefix And Ignore Rules** shapes what a source lists and what it leaves out, followed by a second graded lab. **Bucket Status And Troubleshooting** reads the conditions and fixes typical faults. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Create a Secret with `accesskey` and `secretkey` and a `Bucket` source for an S3-compatible server.
- Allow a server that uses plain HTTP with `insecure: true`, and say why a real one should not need it.
- Explain how the revision of a bucket is computed.
- Start a reconciliation with `flux reconcile` or the `reconcile.fluxcd.io/requestedAt` annotation, without changing the interval.
- Read the `status.artifact` of a source and say what each field is for.
- Explain how many artifacts source-controller keeps, and for how long.
- Pick the provider that fits the object store, and limit a source with `prefix` and `ignore`.
- Read the conditions of a `Bucket` and fix a wrong key, name, endpoint or `insecure` setting.

## Before you start

You need Kubernetes basics (namespaces, Deployments, Secrets, `kubectl exec`), and you should know that a Flux `Kustomization` is the Flux object that applies one folder of a source's artifact to the cluster.

Your playground is a single-node `kind` cluster with **Flux v2.9.6** and the `flux` command-line tool. In the namespace `s3` it runs:

| Name | What it is |
| --- | --- |
| `versitygw` (Service `s3`, port `9000`) | An S3-compatible server over plain HTTP, at `s3.s3.svc.cluster.local:9000`. Lab-only access key `flux-s3`, secret key `flux-s3-secret` |
| bucket `podinfo` | `namespace.yaml`, `deployment.yaml` (2 replicas), `service.yaml` and the Kustomize file `kustomization.yaml` |
| `s3-client` | A pod with the `aws` command-line tool, already set up for this server. You upload through it |

No Flux object reads the bucket yet. Look at the bucket from the client pod:

```sh
kubectl -n s3 exec deploy/s3-client -- aws s3 ls s3://podinfo
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
