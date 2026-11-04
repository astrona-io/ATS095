# Making Changes Stick And Sharding

A change made with `kubectl edit` works until the next time something re-applies the Flux manifests. In a bootstrapped cluster that something is the Flux `Kustomization` `flux-system`, which keeps the controllers as the Git repository says.

## Why the edit disappears

`flux bootstrap` commits the controller manifests to `clusters/<name>/flux-system/gotk-components.yaml`, and the Flux `Kustomization` `flux-system` applies that file. It applies it every interval with server-side apply, so a field you changed by hand is set back. The change you want belongs in Git.

## Patch the controllers in Git

In the bootstrap folder, the file `kustomization.yaml` lists the generated `gotk-components.yaml`. Add a `patches` entry there:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - target:
      kind: Deployment
      name: source-controller
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --concurrent=8
      - op: replace
        path: /spec/template/spec/containers/0/resources/limits/memory
        value: 2Gi
```

Commit it and the `flux-system` Kustomization rolls the change. Keep every tuning patch in this file, so that an upgrade with `flux bootstrap` regenerates `gotk-components.yaml` and leaves your patches in place.

Before you commit a patch that appends an argument, make sure the flag is not already in the generated list: a patch cannot tell, and you would get two copies.

## Sharding

One source-controller has one queue. To split the sources between controllers, run more than one and give each a label selector:

- Each source carries a label such as `sharding.fluxcd.io/key: shard1`.
- Each controller runs with `--watch-label-selector=sharding.fluxcd.io/key=shard1` (or `notin` for the main one, so it skips the sharded sources).
- Each controller needs its own name, Service and storage, and the consumers must be told which Service serves the artifacts through `--storage-adv-addr`.

Treat sharding as a late step. Tune concurrency and resources first; sharding adds a second controller to run, upgrade and watch. The Flux documentation has a procedure for horizontal scaling that you should follow instead of building the manifests by hand.

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system get deployment source-controller -o yaml | grep -n "watch-label-selector" || echo "no selector set"
```

## Common pitfalls

- Editing the Deployment in the cluster and calling it done.
- Appending a flag in a patch while the generated manifest already holds it.
- Sharding before the simpler fixes (intervals, `--concurrent`, memory) were tried.
