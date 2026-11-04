# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** source-controller artifacts

## Scenario

The Flux `Kustomization` `podinfo` applies `./apps/podinfo` from the `GitRepository` `fleet`, and podinfo runs 2 replicas. Your team lead wants proof of what source-controller stored and served after the next change: the revision, the digest and the number of files in the artifact.

The pod `artifact-reader` in the namespace `flux-system` can reach the artifact server (the Flux network policies block other namespaces). The ConfigMap `lab-initial` in the namespace `default` holds the revision `fleet` served when the lab started.

For commands that call Gitea from your machine, start the port-forward in a second terminal first, and leave it running. If `gitea.localtest.me` does not resolve on your machine, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

## Your task

1. Change `apps/podinfo/deployment.yaml` in `gitops/fleet` on `main` so that podinfo asks for 4 replicas. Commit it to Git.
2. Wait until `fleet` serves the new revision and the Flux `Kustomization` `podinfo` applied it.
3. Create the ConfigMap `artifact-proof` in the namespace `flux-system` with three keys:
   - `revision`: the revision of the new artifact (the full `main@sha1:...` value).
   - `digest`: the digest of the new artifact, with the `sha256:` prefix. Compute it from the file the artifact server sends, with `sha256sum`, and compare it with `status.artifact.digest`.
   - `files`: the number of regular files in the artifact, counting files and not folders.

## Constraints

- Keep the names `fleet`, `podinfo` and `artifact-reader`. Do not create a second `GitRepository`.
- Change only the replica count in Git.
- Read the artifact through `artifact-reader`; do not copy values from an old revision.

## Done when

- `fleet` serves a revision other than the one in `lab-initial`, and podinfo applies it with 4 ready replicas.
- `artifact-proof` holds the current revision, the sha256 digest of the served file (equal to `status.artifact.digest`) and the right number of files.
