# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Receivers

## Scenario

The build job writes the podinfo manifests to the bucket `podinfo` on the S3-compatible server in the namespace `s3`. The `Bucket` `podinfo` and the Flux `Kustomization` `podinfo` in `flux-system` deliver it, and podinfo runs 2 replicas. The platform team allows source checks every 30 minutes and no more often, so a new upload waits half an hour. The build job should call a webhook after each upload instead.

The pod `s3-client` in `s3` has the `aws` command-line tool and `curl`. Webhooks reach the cluster through the Service `webhook-receiver` in `flux-system`, port 80.

## Your task

1. Create a Secret in `flux-system` with a key `token` that holds a random string, and a `Receiver` of type `generic` that uses it and selects the `Bucket` `podinfo`.
2. Wait until the `Receiver` is Ready and read its `status.webhookPath`.
3. Act as the build job: change `deployment.yaml` in the bucket to 3 replicas and upload it.
4. Call the webhook with an HTTP `POST` from the pod `s3-client`, and check that the cluster runs 3 replicas.

## Constraints

- Keep the interval of the `Bucket` at `30m`.
- Do not use `flux reconcile` or edit the annotation `reconcile.fluxcd.io/requestedAt` yourself for the change.
- Do not apply the manifests with `kubectl` yourself.

## Success criteria

- A `Receiver` of type `generic` is Ready, has a `webhookPath`, and selects only the `Bucket` `podinfo`.
- The `Bucket` has a reconcile request that it handled, and still has the interval `30m`.
- `deployment.yaml` in the bucket asks for 3 replicas, and podinfo runs 3 ready replicas from the current `Bucket` revision.
