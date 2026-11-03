# GitRepository Status, Conditions And Events

A `GitRepository` that stops working does not print an error on your terminal. It records the reason in its own status, and the other Flux objects that depend on it wait. The skill this part teaches is reading that record: finding out whether a source is healthy, what it fetched, and why it failed. Most of the time the answer is already written in the object, in plain words.

## Read the status of a working source

Start with the healthy `GitRepository` `fleet`. The summary command shows one row for each Git source:

<!-- astrona:playground:renew -->

```sh
flux get sources git
```

The row shows the name, the revision, whether the source is suspended, whether it is `Ready`, and a message. A healthy source has `READY` as `True` and a message that starts with `stored artifact for revision`. The row is a summary of the **status** of the object: the part of a Flux object that the controller writes, as opposed to the `spec`, which you write. To see the whole status, use `kubectl`:

```sh
kubectl -n flux-system describe gitrepository fleet
```

Near the bottom, the `Status` section holds three things you will use every time: the `Artifact`, the `Conditions` and the `Observed Generation`. Below it, the `Events` list shows what the controller did recently.

## The artifact fields

The `status.artifact` field describes the file that source-controller produced from the fetched commit. It has these fields:

| Field | What it holds |
| --- | --- |
| `revision` | The reference and commit, such as `main@sha1:<commit>` |
| `digest` | The checksum of the artifact file |
| `url` | The address inside the cluster where other controllers download the file |
| `path` | The path of the file in the storage of source-controller |
| `size` | The size of the file in bytes |
| `lastUpdateTime` | When source-controller last wrote the artifact |

If `status.artifact` is empty, source-controller has never produced an artifact for this object, so no other controller can use it. If it holds an older revision than you expect, the source has an artifact from an earlier fetch and a newer fetch is failing or has not run yet.

## Conditions

A **condition** is one entry of a list in the status. Each condition has a `type`, a `status` of `True`, `False` or `Unknown`, a `reason` that is a short code, and a `message` in words. A `GitRepository` uses these types:

| Type | What it means |
| --- | --- |
| `Ready` | `True` when the artifact is up to date with the remote revision. `False` when the last fetch failed. `Unknown` while the controller is working on a change |
| `Reconciling` | Present only while its status is `True`. It means the controller is fetching a new revision or applying a change. The reason is `Progressing` or `ProgressingWithRetry` |
| `Stalled` | Present only when the controller cannot continue without a change by you, for example an invalid specification. The controller does not retry until the object changes |
| `FetchFailed` | `True` when the last fetch failed. The reason is `AuthenticationFailed` or `GitOperationFailed` |
| `ArtifactInStorage` | `True` while the artifact exists in storage. It stays `True` after a failed fetch, because the old artifact is still there |
| `ArtifactOutdated` | Present with the reason `NewRevision` when a new revision was found and the artifact is being replaced |

Print only the conditions, as type, status, reason and message:

```sh
kubectl -n flux-system get gitrepository fleet \
  -o jsonpath='{range .status.conditions[*]}{.type}{"  "}{.status}{"  "}{.reason}{"  "}{.message}{"\n"}{end}'
```

For `fleet`, `Ready` and `ArtifactInStorage` are `True` with the reason `Succeeded`. The other types are absent, because their status would be `True` only during a problem or a change. That makes the list a quick test: a healthy source has no `FetchFailed` and no `Stalled`.

## Generations

Every change to the `spec` raises `metadata.generation` by one. The field `status.observedGeneration` holds the latest generation that source-controller handled to a result: a ready state or a stalled state. Compare them:

```sh
kubectl -n flux-system get gitrepository fleet \
  -o jsonpath='{.metadata.generation}{"  "}{.status.observedGeneration}{"\n"}'
```

When the two numbers are equal, the status describes your current `spec`. When `observedGeneration` is lower, either the controller has not reached your change yet or the fetch is still failing, so the status describes an older request. This is how you tell an old error from a new one.

## Break the source and read the failure

Point `fleet` at a tag that does not exist and watch the conditions change. This is a safe fault, because the earlier artifact stays in storage:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"ref":{"tag":"v9.9.9"}}}'
flux reconcile source git fleet
```

Run the `describe` command again. The summary row now shows `READY` as `False`, and the message reports that source-controller could not find the reference. `Ready` is `False`, `FetchFailed` is `True` with the reason `GitOperationFailed`, and `ArtifactInStorage` is still `True`. The generation is higher than the observed generation. The `Events` list shows the same message each time the controller retries, with longer pauses between the tries.

Flux also keeps these events for you to read from the command line, without the rest of the `describe` output:

```sh
flux events --for GitRepository/fleet
```

Restore the branch. The field `tag` takes precedence over `branch`, so remove it by setting it to `null`:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"ref":{"tag":null}}}'
flux reconcile source git fleet
```

## Common failure messages

The `reason` tells you the kind of failure, and the `message` tells you the cause. These are the ones you meet most often:

- A message that the Secret was not found: `spec.secretRef.name` names a Secret that does not exist in the `GitRepository` namespace. Check the spelling of the name and the namespace.
- A message that authentication is required or failed: the Secret exists, but the Git server rejected the user name and password, the token, or the SSH key.
- A message that a remote reference cannot be found: the branch, tag or commit in `spec.ref` is not in the repository. Compare it with the names in the Git server.
- A message about a context deadline or a timeout: the Git server did not answer within `spec.timeout`. The default is `60s`.
- A message that no tag matches a semver range: no tag of the repository fits the range in `spec.ref.semver`.

Read the message in full before you change anything, and read it again after each change. A fixed fault often uncovers the next one, because source-controller stops at the first error it meets.

You can now find out what a source fetched, whether it is healthy, and why it is not. What remains is acting on a source quickly and repeatably, without editing YAML by hand each time, and that is what the Flux command-line tool is for.

## Common pitfalls

> [!WARNING]
> - **Reading only the summary row.** The row shows one message, cut short. Use `kubectl describe` or the `jsonpath` command for the full conditions.
> - **Trusting an old message.** If `observedGeneration` is lower than `metadata.generation`, the status describes an earlier version of the object.
> - **Thinking `ArtifactInStorage` `True` means the source is healthy.** The old artifact stays in storage after a failed fetch. Read `Ready` and `FetchFailed` as well.
> - **Fixing the second fault before reading the message again.** After each fix, run the status command again. The next message is the next fault.
> - **Waiting for a `Stalled` source to retry.** A stalled source waits for a change to the object. Change the `spec` or request a reconcile.

## Your mission: Find Why A GitRepository Is Not Ready

You can now read the conditions, events and generations of a `GitRepository` and match a failure message to a cause. The graded lab gives you a `GitRepository` that cannot fetch and a Flux `Kustomization` that waits for it. It asks you to find every reason in the status, fix the object and prove that `podinfo` is deployed.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-095-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-010/module-01/labs/lab-02
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-02
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-095-lab-010-01-02
astrona start ats-095-playground-010-01
```
