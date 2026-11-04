# Flags For Concurrency, Retention And Caches

source-controller takes its settings as command-line arguments. Read them first, then change the few that matter.

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system get deployment source-controller \
  -o jsonpath='{.spec.template.spec.containers[0].args}' | jq
```

## The flags that matter for capacity

| Flag | What it controls |
| --- | --- |
| `--concurrent` | How many reconciliations run at the same time for each kind of source. The default is a small number (check the flag reference for your version) |
| `--requeue-dependency` | How long a source waits before it checks again when a dependency (an included repository) is not ready |
| `--artifact-retention-records` | How many artifacts of one source to keep |
| `--artifact-retention-ttl` | How long an older artifact is kept |
| `--storage-path` | The folder for artifacts. Keep `/data` unless you also move the volume |
| `--storage-adv-addr` | The address written into artifact URLs |
| `--helm-cache-max-size`, `--helm-cache-ttl`, `--helm-cache-purge-interval` | The in-memory cache of Helm repository indexes. A cache avoids a download per chart, and costs memory |
| `--watch-label-selector` | Reconcile only objects with a matching label. This is the basis for sharding |
| `--watch-all-namespaces` | Watch every namespace (the default) |

The format of the flags is `--flag=value`. Prefer that form: it is one argument, so a tool that rewrites the list finds and replaces it exactly.

## Concurrency in practice

`--concurrent=8` lets the controller work on up to eight sources of a kind at once. More concurrency lowers the delay in the queue and raises peak CPU, memory and network use. If the limit on memory is tight, a high value can cause the `OOMKilled` you wanted to avoid. Raise it in steps and look at the pod.

## Retention in practice

A larger `--artifact-retention-records` keeps more files per source and uses more disk. A longer `--artifact-retention-ttl` keeps files longer even when the number is within the limit. For most clusters the defaults are right; change them when you need history on the disk for debugging, or when you run out of space.

## Rewrite the args with jq

Replace an argument instead of adding a second copy:

```sh
kubectl -n flux-system get deployment source-controller -o json | jq '
  .spec.template.spec.containers[0].args |=
    (map(select(startswith("--concurrent") | not)) + ["--concurrent=4"])' | kubectl replace -f -
kubectl -n flux-system rollout status deployment/source-controller
```

Two copies of the same flag are ambiguous; a Go flag parser takes the last one, and a reader of the manifest has to know that.

## Common pitfalls

- Using `--concurrent 8` as two arguments in a list that you edit by script.
- Removing `--storage-path` or changing it without a matching volume.
- Setting retention to `1` and then wondering why a slow consumer sees a missing file: it asked for an artifact that was just replaced. It retries and gets the new one.
