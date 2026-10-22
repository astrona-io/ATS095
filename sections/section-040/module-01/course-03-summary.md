# Summary

A bucket on an S3-compatible server is a third place Flux can read manifests from. Working with it also showed when every Flux source fetches, and what source-controller keeps afterwards.

## What you learned

A `Bucket` source names the server in `endpoint`, the bucket in `bucketName`, and the credentials in `secretRef`. With the default provider, `generic`, the Secret holds exactly the keys `accesskey` and `secretkey`; the cloud providers can use the cloud's own identity instead. `insecure: true` allows a server that uses plain HTTP. source-controller builds the revision from the list of object keys and their ETags, so it is a `sha256:` digest that changes with the content and stays the same for an identical upload. A Flux `Kustomization` reads the bucket through `sourceRef.kind: Bucket`, with the path of the manifests inside the bucket.

A source fetches at its `interval`, when its spec changes, or when someone requests a reconciliation. A request is the annotation `reconcile.fluxcd.io/requestedAt` with a new value; `flux reconcile` sets it and waits, and a `Receiver` sets it when a webhook arrives. When a source gets a new revision, the Flux `Kustomization` that reads it applies the new artifact without waiting for its own interval. Requesting one reconciliation is better than shortening an interval for everyone.

Every source reports its artifact in `status.artifact`: the `revision`, the `digest` of the stored file, the in-cluster `url`, the storage `path`, the `size` and the `lastUpdateTime`. source-controller keeps the newest artifacts per object, two by default (`--artifact-retention-records`), and garbage-collects older ones after one minute (`--artifact-retention-ttl`). The storage is local to the pod, and a restart only means one fetch more. The key facts to remember are these:

- `accesskey` and `secretkey`, with exactly those names, for the `generic` provider.
- Same content, same revision: an identical upload changes nothing.
- `reconcile.fluxcd.io/requestedAt` needs a new value each time.
- Reconcile the source, or use `--with-source`, to fetch new content now.

<!-- astrona:playground:destroy -->
