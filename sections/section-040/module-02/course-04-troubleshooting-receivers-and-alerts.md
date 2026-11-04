# Troubleshooting Receivers And Alerts

A webhook is a path with a secret in it, and an alert is a chain of three objects. When nothing arrives, the question is always where the chain broke. This part gives you the checks in order and causes the common faults in the playground.

## A Receiver that is not Ready

Read the conditions and the events of the Receiver:

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system get receiver podinfo-upload -o jsonpath='{range .status.conditions[*]}{.type}{"\t"}{.status}{"\t"}{.reason}{"\t"}{.message}{"\n"}{end}'
flux events --for Receiver/podinfo-upload
```

`Ready` is `True` and `status.webhookPath` is set when the Secret exists, has the key `token` and the type is valid. Break it on purpose by pointing the Receiver at a Secret that does not exist:

```sh
kubectl -n flux-system patch receiver podinfo-upload --type=merge -p '{"spec":{"secretRef":{"name":"missing"}}}'
sleep 5
kubectl -n flux-system get receiver podinfo-upload -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
kubectl -n flux-system patch receiver podinfo-upload --type=merge -p '{"spec":{"secretRef":{"name":"webhook-token"}}}'
```

The message says that the Secret was not found. A Secret without the key `token` gives a similar message. Fix the Secret, and the Receiver becomes Ready on its next reconcile.

## A call that does nothing

If the Receiver is Ready and a call still does not reconcile, check from the outside in:

1. **Did the call arrive?** Look at the log of the controller: `kubectl -n flux-system logs deploy/notification-controller --tail=20`. A refused call is logged with the reason.
2. **Is the path current?** After a token change, the old path returns an error such as 404. Read `status.webhookPath` again.
3. **Is the method `POST`?** Other methods are refused.
4. **Is the type right?** A `github` Receiver ignores events that are not in `spec.events`, and rejects a request whose signature does not match.
5. **Does the target exist?** A resource in the list that does not exist is skipped with a log line, and the other entries still get the request.
6. **Is the target suspended?** A suspended source takes the request and does nothing.

Compare the two timestamps on the target to see whether a request was handled. They are equal when it was:

```sh
kubectl -n flux-system get bucket podinfo -o jsonpath='{.metadata.annotations.reconcile\.fluxcd\.io/requestedAt}{"\n"}{.status.lastHandledReconcileAt}{"\n"}'
```

## An Alert that sends nothing

Walk the chain in order:

1. **Is there an event?** `flux events --for Bucket/podinfo`. If the source emitted nothing, no Alert can send anything.
2. **Does the Alert select it?** The `kind` and `name` of the entry must match, in the namespace of the Alert, and the severity must be low enough.
3. **Do the filters remove it?** An `inclusionList` that matches nothing silences the Alert.
4. **Is the Provider Ready and correct?** `kubectl -n flux-system get providers`, and read the address and the Secret.
5. **Is the Alert suspended?** `spec.suspend: true` stops it.
6. **Does the destination answer?** `kubectl -n flux-system logs deploy/notification-controller` shows a failed delivery with the HTTP status of the destination.

Break step 2 to see how quiet that failure is. Change the severity of the Alert to `error`, trigger a new artifact and read the sink:

```sh
kubectl -n flux-system patch alert bucket-events --type=merge -p '{"spec":{"eventSeverity":"error"}}'
flux reconcile source bucket podinfo
kubectl -n s3 logs deploy/sink --tail=2
kubectl -n flux-system patch alert bucket-events --type=merge -p '{"spec":{"eventSeverity":"info"}}'
```

A new artifact is an `info` event, so with `error` the sink gets nothing, and no object turns red. Nothing is broken; the rule does exactly what it says. That is why alerts are the last thing to trust: check them with a test event after every change.

## Common pitfalls

> [!WARNING]
> - **Debugging the sink first.** Start at the source: no event, no alert.
> - **Reading only the Receiver, not the target.** A Ready Receiver says nothing about whether the target handled the request.
> - **Rotating a token without updating the sender.** The old path stops at once.
> - **Forgetting the namespace.** Receivers and Alerts look for their targets and Providers in their own namespace unless told otherwise.
