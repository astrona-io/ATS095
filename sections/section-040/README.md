# Section 040: Bucket Sources, Triggers And Artifacts

Some teams do not keep their manifests in Git or a registry at all: a build job writes them to an S3-compatible bucket, and the cluster reads them from there. Flux supports that with the `Bucket` source. The same section also answers two questions that apply to every source kind. When does source-controller fetch, and how do you make it fetch now? And what does it keep after it has fetched?

**Topic covered:** Bucket sources, reconciliation triggers and artifacts

## What you will learn

- The fields of a `Bucket`: `provider`, `bucketName`, `endpoint`, `insecure` and `secretRef`, and the Secret keys `accesskey` and `secretkey`.
- How source-controller computes the revision of a bucket, and why uploading the same content again changes nothing.
- The three ways a reconciliation starts: the interval, `flux reconcile`, and the annotation `reconcile.fluxcd.io/requestedAt`.
- What the `status.artifact` of a source holds: `revision`, `digest`, `url`, `size` and `lastUpdateTime`.
- How source-controller keeps and garbage-collects older artifacts.
- Limiting a `Bucket` with `prefix` and `ignore`, the cloud providers, and reading its conditions to fix a failing source.
- Receivers: the types `generic`, `generic-hmac`, `github` and `gitlab`, the token and `status.webhookPath`, and exposing the webhook.
- Sending source events to a webhook with a `Provider` and an `Alert`.

## The learning path

Each module has a landing page, several parts, graded labs right after the parts they test, and a summary. The landing page also starts the module's playground.

### 1. Sync From A Bucket And Control When Flux Fetches

The playground holds an S3-compatible server in the namespace `s3`, with the bucket `podinfo` already filled with the podinfo manifests, and a client pod `s3-client` for uploads.

1. Bucket Sources On S3-Compatible Storage
2. Reconciliation Triggers, Artifacts And Garbage Collection, followed by the lab **Deliver From A Bucket And Trigger A Reconcile**
3. Providers, Prefix And Ignore Rules, followed by the lab **Scope A Bucket With A Prefix And Ignore Rules**
4. Bucket Status And Troubleshooting
5. Summary

### 2. Receivers And Source Notifications

The playground adds a small HTTP `sink` that prints every POST, next to the S3-compatible server.

1. Receivers: A Webhook That Reconciles A Source
2. Receiver Types, Tokens And Exposure, followed by the lab **Trigger A Bucket From A Webhook**
3. Notify On Source Events With Provider And Alert
4. Troubleshooting Receivers And Alerts
5. Summary

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
