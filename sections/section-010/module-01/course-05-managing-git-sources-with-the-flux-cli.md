# Managing Git Sources With The Flux CLI

You have changed `fleet` by applying YAML and by patching it with `kubectl`. That works, but it is slow for daily operations: you want to create a source in one line, stop it while you work on the repository, and make it fetch now. The `flux` command-line tool does these jobs. This part shows the commands for the life of a `GitRepository`, and the three fields that they set: `spec.interval`, `spec.timeout` and `spec.suspend`.

## Create a source with one command

`flux create source git` builds a `GitRepository` from flags and applies it. Create a second source for the same repository. It follows `main` and checks every ten minutes:

<!-- astrona:playground:renew -->

```sh
flux create source git fleet-copy \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --branch=main \
  --secret-ref=fleet-auth \
  --interval=10m
```

The command creates the object in `flux-system` and waits until it is `Ready`. The flags map to fields: `--url` to `spec.url`, `--branch`, `--tag`, `--tag-semver` and `--commit` to `spec.ref`, `--secret-ref` to `spec.secretRef.name` and `--interval` to `spec.interval`. Without `--branch`, the tool uses `master`, as the API does. The flag `--export` prints the YAML and applies nothing, which is a quick way to produce a file for a Git repository.

## Look at sources

List every kind of source in one table, and then only the Git sources:

```sh
flux get sources all
flux get sources git
```

Each row shows the revision, the `SUSPENDED` column and the `READY` column. Add `--all-namespaces` to look in every namespace, and `--watch` to keep the table running until you stop it. Both flags are useful when a source is slow to become ready.

To read an object as YAML, ask `flux export`. It prints the object without the status and without fields set by the cluster, so you can store it in Git:

```sh
flux export source git fleet-copy
```

The output holds the `apiVersion`, `kind`, `metadata.name`, `metadata.namespace` and the `spec` with the interval, the URL, the reference and the Secret name. Use `--all` to export every Git source.

## Reconcile now

The interval is how often source-controller checks the remote repository. With `fleet-copy` at ten minutes, a new commit can wait up to ten minutes. A **reconcile request** makes the controller check now. The command writes the annotation `reconcile.fluxcd.io/requestedAt` with the current time, and the controller acts when the value differs from the last one it handled, which it records in `status.lastHandledReconcileAt`:

```sh
flux reconcile source git fleet-copy
```

The command waits for the result and prints the revision it found. A reconcile request does not change the `spec`, so it does not change the generation. If nothing changed in Git, the revision stays the same and the artifact stays the same.

## Suspend and resume

**Suspending** a source stops source-controller from fetching it. The field is `spec.suspend`. The objects that read the artifact keep using the last one. Suspend the source while you rewrite the history of a branch, or while you investigate a problem and do not want new commits to reach the cluster:

```sh
flux suspend source git fleet-copy
flux get sources git
```

The `SUSPENDED` column shows `True` for `fleet-copy`. A reconcile request does not fetch while the source is suspended. Resume it to start again:

```sh
flux resume source git fleet-copy
```

The resume command clears the flag and runs a reconcile at once. The Flux documentation recommends removing `spec.suspend` over setting it to `false` when a source is managed from Git, so that the field does not linger in the file.

## Timeout and interval in the spec

Two durations in the `spec` control the work of source-controller. `spec.interval` is required, and it is how often the source is checked. `spec.timeout` is the time allowed for one Git operation such as a clone, and its default is `60s`. A large repository on a slow network can need more. Raise it without touching the other fields:

```sh
kubectl -n flux-system patch gitrepository fleet-copy --type=merge -p '{"spec":{"timeout":"2m"}}'
```

A change to the `spec` raises the generation, and the controller handles it at once, outside the interval. A short interval gives faster updates and more requests to the Git server. A long interval is cheaper, and a reconcile request covers the urgent case.

## Follow an object back to its source

Two commands go the other way, from what runs in the cluster to where it came from. `flux tree kustomization` lists the objects that a Flux `Kustomization` created. `flux trace` takes one object and prints the chain behind it: the Flux `Kustomization` that applied it, the source, and the revision:

```sh
flux tree kustomization podinfo
flux trace deployment podinfo --namespace podinfo
```

The trace for the Deployment `podinfo` names the Flux `Kustomization` `podinfo`, the `GitRepository` `fleet`, the path, and the revision of each. When a workload has the wrong version, this tells you in one command which source and which revision to look at.

Clean up the extra source:

```sh
flux delete source git fleet-copy --silent
```

You can now create, list, export, reconcile, suspend, resume and delete a `GitRepository` with the `flux` tool, and set its interval and timeout. Together with the status from the previous topic, that is the full operating routine for a Git source.

## Common pitfalls

> [!WARNING]
> - **Forgetting `--branch` in `flux create source git`.** The default is `master`, and a repository that uses `main` never becomes ready.
> - **Leaving a source suspended.** It keeps the old artifact and fetches nothing. Check the `SUSPENDED` column when a change does not arrive.
> - **Using a very short interval to get fast updates.** It sends many requests to the Git server. Use a reconcile request for an urgent change.
> - **Editing a source with `kubectl` when Git manages it.** The next sync from Git restores the old value. Change the file in Git.
> - **Expecting `flux export` to include the status.** It prints the `spec` side only.
