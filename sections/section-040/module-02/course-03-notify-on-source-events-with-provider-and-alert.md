# Notify On Source Events With Provider And Alert

A Receiver brings an event in. This part sends events out. Every Flux controller emits **events** for what it does: a source stored a new artifact, a fetch failed, a sync was applied. notification-controller forwards the ones you choose to the places you choose.

Two objects cooperate. A **`Provider`** describes one destination: its type, an address and, if needed, a Secret with a token. An **`Alert`** says which events go to which Provider: the event sources, the lowest severity, and optional filters. The Alert and the Provider use the API `notification.toolkit.fluxcd.io/v1beta3`.

## Create a Provider

The type `generic` posts the event as JSON to an address. The playground's `sink` prints every POST it gets, which makes the output easy to see:

<!-- astrona:playground:renew -->

```sh
kubectl apply -f - <<'EOF'
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Provider
metadata:
  name: sink
  namespace: flux-system
spec:
  type: generic
  address: http://sink.s3.svc.cluster.local:8080/flux
EOF
```

Other types send to chat (`slack`, `discord`, `msteams`, `googlechat`, `telegram`), to Git hosts to set a commit status (`github`, `gitlab`, `bitbucket`), or to incident and metrics tools. For most chat types, the address and a token sit in a Secret named by `secretRef`, so no credentials appear in the manifest. The CLI form is `flux create alert-provider`.

## Create an Alert

An `Alert` names the Provider and the event sources. `eventSeverity` is `info` or `error`: `info` sends everything, `error` sends only failures. Each source entry has a `kind` and a `name`, and the name can be `*` for all objects of that kind in the namespace:

```sh
kubectl apply -f - <<'EOF'
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Alert
metadata:
  name: bucket-events
  namespace: flux-system
spec:
  providerRef:
    name: sink
  eventSeverity: info
  eventSources:
    - kind: Bucket
      name: "*"
EOF
```

With the CLI: `flux create alert bucket-events --provider-ref sink --event-source 'Bucket/*' --event-severity info`.

## Trigger an event and read it

Upload a change and request a fetch. The `Bucket` stores a new artifact, which is an event of severity `info`:

```sh
kubectl -n s3 exec deploy/s3-client -- aws s3 cp s3://podinfo/deployment.yaml - \
  | sed 's/replicas: [0-9]*/replicas: 4/' \
  | kubectl -n s3 exec -i deploy/s3-client -- aws s3 cp - s3://podinfo/deployment.yaml
flux reconcile source bucket podinfo
sleep 5
kubectl -n s3 logs deploy/sink --tail=3
```

The sink prints the path `/flux` and a JSON document. Its main fields are `involvedObject` (the kind, name and namespace of the source), `severity`, `reason` (for a new artifact, `NewArtifact`), `message`, `reportingController` and a `metadata` map with the revision. That one document is all a webhook receiver on the other end needs to post a chat message or open a ticket.

## Filter the stream

Two lists keep the noise down. `inclusionList` keeps only messages that match one of the regular expressions, and `exclusionList` drops messages that match. A third field, `summary`, adds a short text, such as the cluster name, to each message, which helps when several clusters send to one channel. The filters apply to the message text:

```yaml
spec:
  eventSeverity: info
  inclusionList:
    - "stored artifact"
  exclusionList:
    - "no changes"
```

For a quieter setup, send `info` events of important sources to a low-priority place and `error` events of all sources to the on-call channel, with two Alerts and two Providers.

## What events a source emits

A source emits an `info` event when it stores a new artifact, with the reason `NewArtifact`. When a fetch fails, it emits an `error` event with the failure message. It does not repeat a failure on every retry; an error event is sent again only when the message changes. This is why a quiet channel does not mean a healthy source: read `flux get sources` as well.

## Common pitfalls

> [!WARNING]
> - **Alert and Provider in different namespaces.** `providerRef` names a Provider in the namespace of the Alert.
> - **`eventSeverity: error` for a new-artifact test.** A new artifact is `info`. Use `info` while you test.
> - **A wildcard that is not what you want.** `name: "*"` means every object of that kind in the namespace of the Alert, which can be a lot of messages.
> - **Putting a token in `spec.address`.** Use `secretRef` so the token is not in a manifest in Git.
