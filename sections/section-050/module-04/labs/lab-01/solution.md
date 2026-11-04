# Solution: Tenant Isolation

Work the task yourself first. Running `astrona submit -c sections/section-050/module-04/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the block

```sh
kubectl -n team-a get kustomization team-a-apps -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
kubectl -n flux-system get deployment kustomize-controller -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}'
```

The message says the cross-namespace reference to `GitRepository/flux-system/fleet` is not allowed, and the flag `--no-cross-namespace-refs=true` is the reason. The fix is not to remove the flag; the tenant gets a source of its own.

## Step 2: Create the credentials and the source in team-a

```sh
flux create secret git fleet-auth -n team-a \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password
flux create source git fleet -n team-a \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --branch=main --secret-ref=fleet-auth --interval=1m
```

## Step 3: Point the Kustomization at it, as the tenant

```sh
kubectl -n team-a patch kustomization team-a-apps --type=merge -p \
  '{"spec":{"serviceAccountName":"team-a","sourceRef":{"kind":"GitRepository","name":"fleet","namespace":"team-a"}}}'
flux reconcile kustomization team-a-apps -n team-a --with-source
```

## Step 4: Check the confinement

```sh
kubectl -n team-a get configmap team-a-config
kubectl auth can-i create namespaces --as=system:serviceaccount:team-a:team-a
kubectl auth can-i get secrets -n flux-system --as=system:serviceaccount:team-a:team-a
```

Both `can-i` answers are `no`: with `serviceAccountName`, kustomize-controller impersonates the account, so a tenant manifest that tries to create a namespace or read a Secret in `flux-system` is rejected.
