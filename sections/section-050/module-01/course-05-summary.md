# Summary

source-controller keeps every fetched revision as a file and serves it to the other controllers.

## What you learned

An artifact is a `tar.gz` of the files of one revision. source-controller writes it below `--storage-path=/data`, an `emptyDir` volume, and serves it through the Service `source-controller` on port 80. The URL names the kind, the namespace and the name of the source and a file named after the revision. `status.artifact` holds the `revision`, the `digest` (`sha256:` plus the hash of the archive), the `url`, the `size` and `lastUpdateTime`. Garbage collection keeps the newest artifact and a few older ones of the same source, as set by `--artifact-retention-records` and `--artifact-retention-ttl`. When the pod is replaced, the storage is empty and every source is fetched again. kustomize-controller and helm-controller read the artifact, check its digest and apply it. The artifact server has no login, and the network policies of `flux-system` are what keeps other namespaces out. The key facts to remember are these:

- The artifact is the only thing a consumer sees; it never reads Git.
- The digest is the hash of the archive; compare it with `sha256sum` of the bytes the server sends.
- Artifacts live in an `emptyDir` and are rebuilt after a pod restart.
- To read one by hand, use a pod in `flux-system`.

<!-- astrona:playground:destroy -->
