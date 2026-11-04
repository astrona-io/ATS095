# Impersonation With serviceAccountName

The kustomize-controller has wide rights: it can create anything. If a tenant's Kustomization used those rights directly, a manifest in the tenant's repository could create a Namespace or a ClusterRoleBinding. **Impersonation** closes that gap. With `spec.serviceAccountName`, kustomize-controller sends every request to the API server as that ServiceAccount, so Kubernetes RBAC decides what is allowed.

<!-- astrona:playground:renew -->

```sh
kubectl -n team-a get kustomization team-a-apps -o jsonpath='{.spec.serviceAccountName}{"\n"}'
```

## Set it

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: team-a-apps
  namespace: team-a
spec:
  interval: 5m
  path: ./tenants/team-a
  prune: true
  serviceAccountName: team-a
  sourceRef:
    kind: GitRepository
    name: fleet
```

The account must exist in the **same namespace** as the Kustomization. Prune, health checks and apply all run as that account.

## Check the confinement

`kubectl auth can-i` can ask as another identity:

```sh
SA=system:serviceaccount:team-a:team-a
kubectl auth can-i create configmaps -n team-a --as=$SA
kubectl auth can-i create namespaces --as=$SA
kubectl auth can-i get secrets -n flux-system --as=$SA
```

The first answer is `yes`, the others are `no`. A manifest in the tenant folder that asks for a Namespace now fails with a forbidden error in the Kustomization's message, and nothing is created.

## A default for everyone

kustomize-controller and helm-controller have the flag `--default-service-account=<name>`. A Kustomization without `serviceAccountName` then applies as that account in its own namespace, which makes a missing field safe by default. The tenant can still set a different account of its own namespace.

## Common pitfalls

- Binding the ServiceAccount to `cluster-admin`. Impersonation then protects nothing.
- Forgetting `serviceAccountName` and relying on the team to remember it. Use the default flag.
- Expecting impersonation to cover the fetch. It limits what is applied; the source's own Secret limits what is fetched.

## Your mission: Tenant Isolation

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-095-playground-050-04
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-050/module-04/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-050/module-04/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-095-lab-050-04
astrona start ats-095-playground-050-04
```
