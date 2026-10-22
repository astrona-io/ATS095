# Solution: Repair An OCI Delivery

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the `OCIRepository` has the right address, allows HTTP, follows a range and is at `1.1.0`; the Flux `Kustomization` reads it and applied `1.1.0`; and both objects were fixed in place.

## Step 1: Read what the source reports

Start with the source, because nothing downstream can work without an artifact:

```sh
flux get sources oci
flux events --for OCIRepository/podinfo
kubectl -n flux-system get ocirepository podinfo -o jsonpath='{.spec}{"\n"}'
```

The `OCIRepository` is not `Ready`, and its spec shows two faults. The `url` ends in `:1.1.0`, but the address of an `OCIRepository` must not hold a tag. And there is no `insecure: true`, so source-controller tries HTTPS against a registry that only speaks plain HTTP. There is also no `ref`, which means the tag `latest`, and this registry has no such tag.

## Step 2: Fix the OCIRepository

Remove the tag from the address, allow plain HTTP, and follow a range with an upper bound:

```sh
kubectl -n flux-system patch ocirepository podinfo --type=merge -p \
  '{"spec":{"url":"oci://registry.localtest.me:5001/podinfo-manifests","insecure":true,"ref":{"semver":">=1.0.0 <2.0.0"}}}'
flux reconcile source oci podinfo
flux get sources oci
```

The `OCIRepository` is `Ready` on `1.1.0@sha256:`. `2.0.0` is outside the range, and `1.1.0` is the highest release inside it.

## Step 3: Read what the Flux Kustomization reports

The source works now, yet the namespace `podinfo` still does not exist. Look at the sync:

```sh
flux get kustomizations
kubectl -n flux-system get kustomization podinfo -o jsonpath='{.spec.sourceRef}{"\n"}'
```

The Flux `Kustomization` names a source of kind `GitRepository` called `podinfo`. No such object exists, so kustomize-controller has no artifact to apply. The `OCIRepository` has the same name but a different kind.

## Step 4: Point the Flux Kustomization at the OCIRepository

```sh
kubectl -n flux-system patch kustomization podinfo --type=merge -p \
  '{"spec":{"sourceRef":{"kind":"OCIRepository","name":"podinfo"}}}'
flux reconcile kustomization podinfo
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

The Flux `Kustomization` is `Ready` on the same `1.1.0@sha256:` revision as the source, and the Deployment runs 3 replicas. The path `./` was already right, because a Flux OCI artifact holds the manifests at its root.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete and recreate both objects | Works, but the task asks for a repair in place, and the grader checks it |
| `ref.tag: 1.1.0` | Runs `1.1.0` today, but never follows the next 1.x release |
| Pin the digest of `1.1.0` | Same, and it overrides any range you add later |
| Create a `GitRepository` named `podinfo` | There is no Git server here; the Flux `Kustomization` must read the `OCIRepository` |
