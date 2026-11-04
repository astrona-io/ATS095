# Summary

Flux can be told about a change by a webhook, and it can tell others about what it did.

## What you learned

A `Receiver` is an HTTP endpoint in notification-controller. It has a `type`, a Secret with a `token` and a list of `resources`. When it is Ready, `status.webhookPath` holds the path `/hook/<hash>`, computed from the token, the name and the namespace. A call sets `reconcile.fluxcd.io/requestedAt` on every listed resource, which starts one reconciliation and leaves the interval alone. The Service `webhook-receiver` in `flux-system` is reachable inside the cluster, and an `Ingress` or a Gateway exposes it with TLS to the outside. The `generic` type is protected only by the secret path. `generic-hmac`, `github` and `gitlab` check a signature or a token header, and `github` and `gitlab` take a list of `events`.

A `Provider` is a destination with a `type`, an `address` and an optional `secretRef`, and an `Alert` connects event sources to a Provider with `eventSeverity` and optional filters. A source emits an `info` event such as `NewArtifact` when it stores an artifact, and an `error` event when a fetch fails. When nothing arrives, start at the source, then the Alert, the Provider and the destination. The key facts to remember are these:

- A Receiver does not poll and does not change an interval; it sets the reconcile request.
- For `generic`, the path is the secret. Prefer a signed type.
- Changing the token changes the path.
- A new artifact is severity `info`; an Alert with `error` will not send it.

<!-- astrona:playground:destroy -->
