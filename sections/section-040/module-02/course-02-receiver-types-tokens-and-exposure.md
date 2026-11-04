# Receiver Types, Tokens And Exposure

The `generic` Receiver is a good first step, but a Git host, a registry or a build system does not call a bare `POST`. Each sends its own headers and proves itself in its own way. This part compares the Receiver types, shows what the token does in each, and explains how a webhook gets from the internet to the controller. It ends with a graded lab.

## The types

`spec.type` selects how the request is checked and which event it carries:

| Type | The caller sends | What proves the caller |
| --- | --- | --- |
| `generic` | Any `POST` | Only the secret path |
| `generic-hmac` | A `POST` with the header `X-Signature` | An HMAC of the body, made with the token |
| `github` | A GitHub webhook | The header `X-Hub-Signature`, an HMAC of the body with the token |
| `gitlab` | A GitLab webhook | The header `X-Gitlab-Token`, which must equal the token |
| `bitbucket`, `harbor`, `dockerhub`, `quay`, `gcr`, `nexus`, `acr`, `cdevents` | The format of that service | The mechanism that service supports |

`github` and `gitlab` Receivers have a list `spec.events`. Only the listed event names reconcile anything, for example `["ping", "push"]` for GitHub or `["Push Hook", "Tag Push Hook"]` for GitLab. An event that is not listed is accepted and ignored. A `generic` Receiver has no events: every valid call counts.

The signed types are safer. With `generic-hmac`, a stolen path is not enough, because the caller must also sign the body with the token. Choose a signed type whenever the sender supports it. Compute a signature by hand to see how it works:

```sh
TOKEN=...   # the value of the key token in the Secret
BODY='{"ref":"refs/heads/main"}'
SIG="sha256=$(printf '%s' "$BODY" | openssl dgst -sha256 -hmac "$TOKEN" | awk '{print $NF}')"
curl -X POST -H "X-Signature: $SIG" -d "$BODY" "https://flux.example.com$HOOK"
```

The command is a sketch for a real setup; the playground has no outside address to call.

## What can a Receiver reconcile?

`spec.resources` is a list of objects. Each entry has `apiVersion`, `kind` and `name`, and may have a `namespace`. The kinds are the Flux source and sync kinds: `GitRepository`, `OCIRepository`, `HelmRepository`, `HelmChart`, `Bucket`, `Kustomization`, `HelmRelease` and the image automation kinds. A single call can reconcile several objects, so one registry webhook can wake several `OCIRepository` objects. Do not select an object that you do not mean to wake: a Receiver has the power to trigger anything in its list, in any namespace that its entries name.

## How a call reaches the controller

notification-controller listens for webhooks on its own port, and the Service `webhook-receiver` in `flux-system` maps port 80 to it. The Service is `ClusterIP`, so it is reachable inside the cluster only, which is what you used in the previous part. For a Git host on the internet, you expose the Service yourself with an `Ingress`, a Gateway API route or a load balancer. Two rules keep this safe:

- Terminate TLS in front, because the path travels in the URL.
- Route only the path prefix `/hook/` to the Service. Everything else on the controller is not for the outside world.

The Receiver does not change when you expose it. The path stays the same, and you give `https://flux.example.com` plus the path to the sender. A Receiver also works with a private network: a CI runner inside the VPN calls the Service address directly.

## Rotating a token

Because the path is a hash of the token, replacing the token changes the path. Update the Secret, wait for the Receiver to be reconciled again, read the new `status.webhookPath`, and give it to the sender. The old path stops working at once. Plan the change as one step with the sender, so no upload falls in the gap.

## Your mission: Trigger A Bucket From A Webhook

The graded lab gives you a delivery that polls every 30 minutes, and asks you to create the Receiver, upload a change and call the webhook, so that the change is applied without touching the interval.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-095-playground-040-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-040/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-095-lab-040-02
astrona start ats-095-playground-040-02
```
