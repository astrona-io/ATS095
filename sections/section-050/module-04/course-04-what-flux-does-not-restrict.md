# What Flux Does Not Restrict

The flag and the ServiceAccount cover two things: which source a tenant may reference, and which rights it applies with. A few holes remain. Know them, and close them with other tools.

## A tenant can point its source anywhere

`spec.url` of a `GitRepository` is free text. A tenant with permission to create sources in its namespace can fetch from any reachable URL, including an internal Git server or an unexpected registry. Flux has no allow-list for URLs. Use an admission policy (for example Kyverno or a ValidatingAdmissionPolicy) that checks `spec.url` against a list.

## A tenant can reach the network

Fetching is done by source-controller, which has network access to whatever the cluster's network policies allow. Restrict egress of source-controller to the Git servers and registries you use.

## Artifacts are not secret

The artifact server has no login. Anyone with a pod in `flux-system` can read every tenant's artifact. Keep tenant workloads out of `flux-system` and keep secrets out of Git (use SOPS or an external secrets tool).

## Sources are visible to the platform

The platform team can read all sources and Secrets. Tenants cannot see each other's objects as long as their RoleBindings stay in their namespaces.

## Limit what a controller watches

`--watch-label-selector` limits which objects a controller reconciles. It is a sharding tool, not a security boundary, because a tenant who may create objects can also add labels.

<!-- astrona:playground:renew -->

```sh
kubectl get gitrepositories,kustomizations -A
kubectl get rolebindings,clusterrolebindings -A -o wide | grep team-a || echo "no bindings for team-a"
```

## Checklist for a new tenant

1. Namespace, ServiceAccount and a RoleBinding limited to that namespace.
2. Credentials Secret and `GitRepository` in the tenant namespace.
3. `serviceAccountName` on every Kustomization, backed by `--default-service-account`.
4. `--no-cross-namespace-refs=true` on the controllers.
5. An admission policy for `spec.url`, and network policies for egress.

## Common pitfalls

- Treating the Flux flags as the whole security model.
- Letting tenants create `ClusterRole` or `ClusterRoleBinding` objects through a permissive account.
- Sharing one credentials Secret between tenants. One leak then affects all of them.
