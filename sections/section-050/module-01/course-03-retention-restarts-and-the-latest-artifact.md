# Retention, Restarts And The Latest Artifact

Each new revision makes a new file. If source-controller kept all of them, the storage would grow without limit. This part explains what it keeps and what happens when the storage disappears.

## Garbage collection

After a source stores a new artifact, source-controller deletes older artifacts of **the same source** by a retention policy. Two flags control it:

| Flag | Meaning |
| --- | --- |
| `--artifact-retention-records` | How many artifacts of one source to keep at most |
| `--artifact-retention-ttl` | How old an artifact may be before it can be deleted |

The newest artifact is always kept, because it is the one in `status.artifact`. The defaults are small (a few records and about a minute; check the exact values for your version in the source-controller flag reference). Raising them keeps more history on disk, and nothing in Flux uses the older files for reconciling.

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system get deployment source-controller \
  -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}'
```

## The latest artifact is the only one that counts

The status holds one artifact. A consumer asks for that one. When a fetch fails, the status keeps the last good artifact, the `Ready` condition turns `False`, and the consumers keep using the file they have. This is why a broken Git server does not delete a running workload.

## What a restart does

Delete the pod:

```sh
kubectl -n flux-system delete pod -l app=source-controller
kubectl -n flux-system rollout status deployment/source-controller
flux get sources git
```

The new pod starts with an empty `emptyDir`. The status objects live in the API server, so they still show the old artifact for a moment, but the files are gone. source-controller notices a source whose artifact is missing from storage, fetches the source again and stores a new file. Until then, a consumer that asks for the URL gets an error and retries. The condition `ArtifactInStorage` tells you whether the file in the status really exists on disk.

For a Git source the effect is a fresh clone. For an OCI source it is a new pull, and for a Bucket a new download. A large number of sources means a burst of work after a restart, which is one reason the next module sizes the controller.

## Common pitfalls

- Believing the artifact survives a rollout. It does not, unless you mount a persistent volume yourself.
- Reading `status.artifact` as proof the file exists. Check `ArtifactInStorage`.
- Raising retention to keep a "backup" of old revisions. Git, the registry or the bucket is the backup.
