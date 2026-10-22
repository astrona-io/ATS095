# Section 040: Bucket Sources, Triggers And Artifacts

Some teams do not keep their manifests in Git or a registry at all: a build job writes them to an S3-compatible bucket, and the cluster reads them from there. Flux supports that with the `Bucket` source. The same section also answers two questions that apply to every source kind. When does source-controller fetch, and how do you make it fetch now? And what does it keep after it has fetched?

**Topic covered:** Bucket sources, reconciliation triggers and artifacts

## What you will learn

- The fields of a `Bucket`: `provider`, `bucketName`, `endpoint`, `insecure` and `secretRef`, and the Secret keys `accesskey` and `secretkey`.
- How source-controller computes the revision of a bucket, and why uploading the same content again changes nothing.
- The three ways a reconciliation starts: the interval, `flux reconcile`, and the annotation `reconcile.fluxcd.io/requestedAt`.
- What the `status.artifact` of a source holds: `revision`, `digest`, `url`, `size` and `lastUpdateTime`.
- How source-controller keeps and garbage-collects older artifacts.

## The learning path

The module has a landing page, two parts, a graded lab right after the part it tests, and a summary. The landing page also starts the module's playground.

### 1. Sync From A Bucket And Control When Flux Fetches

The playground holds an S3-compatible server in the namespace `s3`, with the bucket `podinfo` already filled with the podinfo manifests, and a client pod `s3-client` for uploads.

1. Bucket Sources On S3-Compatible Storage
2. Reconciliation Triggers, Artifacts And Garbage Collection, followed by the lab **Deliver From A Bucket And Trigger A Reconcile**
3. Summary

## Section capstone: Repair A Bucket Source

The capstone is one graded scenario with several independent faults in a `Secret`, a `Bucket` and a Flux `Kustomization`. The source never produces an artifact, and even once it does, the sync applies nothing. You fix each object in place until podinfo runs from the bucket. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-095-capstone-040
```
