# Fixing Safely And Proving It

The fix is not done when the source turns `Ready`. It is done when the cluster runs what the source now serves.

## Keep names, change values

Other objects refer to a source by name: Flux `Kustomization` objects, `HelmChart` objects, alerts. Patch the field or replace the Secret under the same name:

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"ref":{"branch":"main"}}}'
flux create secret git fleet-auth --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password --export | kubectl apply -f -
```

Replacing a Secret changes the data under the same name. The source reads the Secret again on the next reconcile.

## Ask for an immediate reconcile

```sh
flux reconcile source git fleet
flux reconcile kustomization podinfo --with-source
```

`--with-source` reconciles the source first and then the Kustomization, in order.

## Prove it

```sh
flux get sources git
flux get kustomizations
flux trace deployment podinfo -n podinfo
```

Three facts: the source is `Ready` with the revision you expect, the Kustomization applied that same revision, and the workload belongs to the Kustomization. If one link is wrong, you know which object to open.

## Leave a fix in Git when the cause is in Git

If the broken field came from a manifest in a repository (a wrong branch, a changed URL), a hand patch is undone by the next apply of that manifest. Fix it in the repository, or the problem comes back.

## Common pitfalls

- Patching the cluster while the source of truth still has the fault.
- Declaring victory at `Ready: True` without comparing revisions.
- Deleting the Secret to "reset" it. A missing Secret is a new failure.
