# What Makes source-controller Busy

source-controller does the same four things for every source: it **fetches** the content, **builds** an archive, **stores** the file and **updates** the status. What it costs depends on the kind of source.

| Source kind | The fetch | What grows with size |
| --- | --- | --- |
| `GitRepository` | A clone of one reference | Memory and disk with the size of the repository and its history |
| `OCIRepository` | A pull of one tag or digest | Network and disk with the size of the layers |
| `HelmRepository` (HTTP) | A download of `index.yaml` | Memory with the number of charts and versions in the index |
| `HelmChart` | A chart download and a package step | CPU and memory with the chart |
| `Bucket` | A listing and a download of changed objects | Network with the number of objects |

## Frequency

Each source runs again every `spec.interval`. A thousand sources with an interval of `1m` give about 17 fetches per second, all day, whether anything changed or not. For a Git source, most of those runs find that the revision is the same and store nothing, but the clone or the `ls-remote` still happens. This is why the usual advice is long intervals plus a Receiver for fast updates.

## Signs of too little capacity

- Sources whose `lastUpdateTime` is much older than their interval: the work queue is long.
- `Ready` messages that mention a timeout while the server is fine: the fetch ran, but late.
- A source-controller pod with restarts and the last state `OOMKilled`.
- A full `emptyDir`: the pod is evicted or writes fail.

<!-- astrona:playground:renew -->

```sh
flux get sources all -A
kubectl -n flux-system get pods -l app=source-controller
kubectl -n flux-system describe pod -l app=source-controller | sed -n '/Last State/,/Ready:/p'
```

## Count the work

```sh
kubectl get gitrepositories,ocirepositories,helmrepositories,helmcharts,buckets -A --no-headers | wc -l
```

Each line is one unit of recurring work. Compare the number with `--concurrent` in the next part.

## Common pitfalls

- Sizing from the number of applications. Size from the number of sources and the size of what they fetch.
- Shortening every interval to get faster updates. Use a Receiver for the few sources that need it.
- Ignoring `HelmRepository` indexes. A large public index can be the biggest single memory cost.
