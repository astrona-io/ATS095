# Prerequisites

Before starting this lab you should be able to:

- Read a `Bucket` source and say where it reads from and with which credentials.
- Use `flux get`, `flux events` and `flux reconcile`.
- Copy files with `aws s3 cp`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **An S3-compatible server** at `s3.s3.svc.cluster.local:9000` over plain HTTP (lab-only access key `flux-s3`, secret key `flux-s3-secret`), and the pod `s3-client` in the namespace `s3` with the `aws` command-line tool already configured for it.
- The bucket `podinfo` with the podinfo manifests. No Flux object reads it yet.

## Working rules

- Everything is graded on the **final state**, so check `flux get` at the end and leave the fix in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- Keep the interval of the `Bucket` at `30m`.
