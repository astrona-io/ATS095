# Reconciliation Triggers, Artifacts And Garbage Collection

The `Bucket` `podinfo` fetches every 30 minutes. A build job that uploads a fix at 10:01 waits until 10:30 at worst, which is too slow for a fix and too fast to justify a shorter interval for every other minute of the day. This part shows the three things that start a reconciliation, makes Flux take an upload at once, and then reads what source-controller keeps afterwards.

## Upload a change and watch nothing happen

Download `deployment.yaml` from the bucket, change it, and upload it again through the client pod. The `aws s3 cp` command copies between the bucket and a local file; `-` means standard input or output:

<!-- astrona:playground:renew -->

```sh
kubectl -n s3 exec deploy/s3-client -- aws s3 cp s3://podinfo/deployment.yaml - > deployment.yaml
sed -i.bak 's/replicas: 2/replicas: 3/' deployment.yaml
kubectl -n s3 exec -i deploy/s3-client -- aws s3 cp - s3://podinfo/deployment.yaml < deployment.yaml
```

The bucket now asks for 3 replicas. Check the source and the cluster:

```sh
flux get sources bucket
kubectl -n podinfo get deployment podinfo
```

Nothing changed: the revision is the old one, and the Deployment still runs 2 replicas. source-controller does not watch the bucket; it looks at it once per interval, and the next look is up to 30 minutes away.

## Three ways a reconciliation starts

A Flux controller reconciles an object for one of three reasons, and you choose between them on purpose:

| Trigger | When to use it |
| --- | --- |
| The `interval` | The normal case: a steady check, sized for how fast changes must arrive |
| A reconcile request | One fetch now, for example after an upload or during an incident |
| A change to the object | Any edit to the object's spec starts a reconciliation at once |

A **reconcile request** is the annotation `reconcile.fluxcd.io/requestedAt` on the object, with a new value each time. The controller sees the new value and reconciles at once. `flux reconcile` sets this annotation for you and then waits for the result. A `Receiver`, a Flux object that accepts webhooks from a Git host or a registry, sets the same annotation when an event arrives, which gives you near-zero delay without polling; it belongs to the notification-controller and is covered with webhooks.

## Make Flux fetch now

Set the annotation yourself first, to see that there is nothing more to it. The value only has to differ from the last one, so the current time works:

```sh
kubectl -n flux-system annotate --overwrite bucket/podinfo reconcile.fluxcd.io/requestedAt="$(date +%s)"
flux get sources bucket
```

Within seconds the `Bucket` has a new `sha256:` revision, because the ETag of `deployment.yaml` changed. kustomize-controller notices that the artifact of its source changed and applies it without waiting for its own interval. Confirm it, this time with the `flux` command that sets the annotation and waits:

```sh
flux reconcile kustomization podinfo --with-source
kubectl -n podinfo get deployment podinfo
```

The Deployment runs 3 replicas. The interval is still 30 minutes; you asked for one fetch, not a faster schedule.

## Read the artifact

Every source reports its current artifact in `status.artifact`. Print it:

```sh
kubectl -n flux-system get bucket podinfo -o jsonpath='{.status.artifact}' | jq
```

The object has six fields. `revision` is the source's own version: here the `sha256` of the object list. `digest` is the hash of the stored `tar.gz` file itself. `url` is the in-cluster address where source-controller serves the file, the address kustomize-controller downloads. `path` is where the file sits in source-controller's storage, `size` is its size in bytes, and `lastUpdateTime` is when this artifact was stored.

Now upload the same file again, unchanged, and request a fetch:

```sh
kubectl -n s3 exec -i deploy/s3-client -- aws s3 cp - s3://podinfo/deployment.yaml < deployment.yaml
flux reconcile source bucket podinfo
kubectl -n flux-system get bucket podinfo -o jsonpath='{.status.artifact.revision}{"\n"}'
```

The revision is the same as before. The content did not change, so the ETags did not change, and source-controller kept the artifact it had. A second upload of the same release is harmless.

## What source-controller keeps

Each new revision gives a new artifact file, and source-controller does not keep them forever. It keeps a small number of the newest artifacts per object, set by the flag `--artifact-retention-records` (default `2`), and deletes older ones once they are older than `--artifact-retention-ttl` (default `1m0s`). This is **garbage collection**: the controller removes artifacts that nothing will ask for again. The flags are set on the source-controller Deployment; to see whether your installation changes the defaults, read its arguments:

```sh
kubectl -n flux-system get deployment source-controller -o jsonpath='{.spec.template.spec.containers[0].args}' | jq
```

When neither flag appears in the list, the defaults apply. The storage is local to the source-controller pod, so a restart of that pod starts with empty storage, and every source fetches again at its next reconciliation. Nothing is lost, because the content lives in Git, the registry or the bucket.

You can now make Flux fetch at once without changing an interval, read every field of an artifact, and explain why the same upload twice changes nothing. That is the whole life of a source revision: fetched, stored, applied, and finally garbage-collected.

## Common pitfalls

> [!WARNING]
> - **Shortening the interval to speed up one change.** A short interval costs requests all day. Request one reconciliation instead.
> - **Setting `requestedAt` to the same value twice.** The controller only reacts to a new value. Use the current time, or `flux reconcile`.
> - **Reconciling the Flux `Kustomization` without its source.** `flux reconcile kustomization` alone applies the artifact the source already has. Add `--with-source`, or reconcile the source first.
> - **Expecting a new revision after an identical upload.** The revision follows the content. Same content, same revision.

## Your mission: Deliver From A Bucket And Trigger A Reconcile

You can now connect a bucket to the cluster and make Flux take a change at once. The graded lab gives you a bucket full of manifests and no Flux objects, and asks you to deliver it with a 30-minute interval, upload a change, and get it applied without waiting.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-095-playground-040-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-040/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-095-lab-040-01
astrona start ats-095-playground-040-01
```
