# Summary

source-controller is a workload with a queue, a memory limit and a disk. You size it from the number and size of the sources.

## What you learned

Every source costs a fetch, an archive, a stored file and a status update, and it repeats every `spec.interval`. Signs of too little capacity are stale `lastUpdateTime` values, timeouts, `OOMKilled` restarts and a full `emptyDir`. The flags that matter are `--concurrent`, `--artifact-retention-records`, `--artifact-retention-ttl`, the Helm cache flags and `--watch-label-selector`; keep `--storage-path=/data` with its volume. Memory is the number to protect: a kill empties the storage and starts a full round of fetches. A change made by hand is undone by the bootstrap, so put it in a `patches` entry in `kustomization.yaml` in Git. Sharding splits the work with label selectors, and comes after the simpler fixes. The key facts to remember are these:

- Use `--flag=value` and keep one copy of each flag.
- A pod restart means a fresh fetch of every source.
- The limit enforces memory, the request places the pod.
- Make the change in Git or the bootstrap undoes it.

<!-- astrona:playground:destroy -->
