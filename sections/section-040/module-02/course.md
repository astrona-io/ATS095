# Receivers And Source Notifications

A source that polls every 30 minutes is a good default, but a build job that has just uploaded a release cannot wait half an hour. A shorter interval makes every source poll all day for the sake of a few uploads. The better answer is to turn the question around: let the system that knows about the change tell Flux. In Flux this is a **Receiver**, an HTTP endpoint that accepts a webhook and asks a source to reconcile at once.

The other direction exists too. A source knows when it stored a new artifact or failed to fetch one, and people want to hear about that in chat or in another system. That is the job of a **Provider**, the place events are sent to, and an **Alert**, the rule that says which events go there.

Keep one sentence in mind: **a Receiver sets the reconcile annotation for you.** It adds no new way of fetching. It is the same `reconcile.fluxcd.io/requestedAt` request from the previous module, started by an HTTP call instead of a person.

The module has four parts. **Receivers: A Webhook That Reconciles A Source** creates a generic Receiver and calls it. **Receiver Types, Tokens And Exposure** compares the types, shows how the secret path works and how to reach the Receiver from outside, followed by a graded lab. **Notify On Source Events With Provider And Alert** sends the events of a source to a webhook and reads them. **Troubleshooting Receivers And Alerts** finds the cause when nothing arrives.

## Learning objectives

After this module you can:

- Create a `Receiver` of type `generic` with a token Secret, and read its `status.webhookPath`.
- Call the webhook and show that it sets the reconcile request on a `Bucket`.
- Pick the right Receiver type, and say what the token protects in each.
- Explain how a Receiver is reached from outside the cluster.
- Create a `Provider` and an `Alert` that send the events of a source to a webhook.
- Debug a Receiver that is not Ready or an Alert that sends nothing.

## Before you start

You need the `Bucket` and the reconcile request from the previous module.

Your playground is a single-node `kind` cluster with **Flux v2.9.6**, which includes notification-controller, the controller that runs Receivers, Providers and Alerts. In the namespace `s3` it runs:

| Name | What it is |
| --- | --- |
| `versitygw` (Service `s3`, port `9000`) | An S3-compatible server over plain HTTP, at `s3.s3.svc.cluster.local:9000`. Lab-only access key `flux-s3`, secret key `flux-s3-secret` |
| bucket `podinfo` | `namespace.yaml`, `deployment.yaml` (2 replicas), `service.yaml` and the Kustomize file `kustomization.yaml` |
| `s3-client` | A pod with the `aws` command-line tool and `curl`, set up for this server |
| `sink` (Service `sink`, port `8080`) | A tiny HTTP server that prints every POST it receives. Read it with `kubectl -n s3 logs deploy/sink` |

No Flux object reads the bucket yet. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
