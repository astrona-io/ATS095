# A Method: Read, Narrow, Fix

Guessing is slow because a source can fail in a dozen places: the network, the DNS name, the credentials, the reference, the files, the consumer. A fixed order cuts the list at every step.

## Step 1: The overview

<!-- astrona:playground:renew -->

```sh
flux get sources all -A
```

One line per source with `READY`, `MESSAGE`, `REVISION` and `SUSPENDED`. Find the lines that are not `True`, and the ones that are suspended.

## Step 2: The condition

```sh
kubectl -n flux-system get gitrepository fleet \
  -o jsonpath='{range .status.conditions[*]}{.type}{"="}{.status}{" ("}{.reason}{"): "}{.message}{"\n"}{end}'
```

Read `reason` and `message`. Check `observedGeneration`: if it is lower than `metadata.generation`, the controller has not seen your last change yet, and the message belongs to the old spec.

| Condition | Meaning |
| --- | --- |
| `Ready` | The overall result |
| `Reconciling` | The controller is working on a change |
| `Stalled` | The controller will not retry until something changes (for example an invalid spec) |
| `FetchFailed` | The last fetch failed (Bucket and OCI; for Git the failure is on `Ready`) |
| `ArtifactInStorage` | The artifact in the status exists in storage |

## Step 3: The events

```sh
flux events --for GitRepository/fleet
```

Events add the history: how many times it failed and when it last worked.

## Step 4: The controller log

```sh
flux logs --kind=GitRepository --name=fleet --since=10m
```

The log holds the full error text from the Git library or the registry client, which is sometimes longer than the condition.

## Step 5: Change one thing

Change one field or one Secret, ask for a reconcile, and read the condition again:

```sh
flux reconcile source git fleet
```

Two causes mean two rounds. The second message only appears after the first cause is gone.

## Common pitfalls

- Reading the message of an old generation.
- Fixing three things at once and not knowing which one worked.
- Deleting and recreating the object. It loses events and history, and it hides what was wrong.
