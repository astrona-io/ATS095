# Tenants And Namespaces

A **tenant** in Flux is not an object. It is a convention: a namespace for the team, a ServiceAccount in it, and a RoleBinding that gives the account rights in that namespace only.

## Create one

The CLI writes the three objects for you. Look at the YAML before you apply it:

<!-- astrona:playground:renew -->

```sh
flux create tenant team-a --with-namespace=team-a --export
```

You see a Namespace, a ServiceAccount and a RoleBinding to the ClusterRole `cluster-admin` limited to that namespace through the RoleBinding. The objects carry the label `toolkit.fluxcd.io/tenant: team-a`. If you want the tenant to have fewer rights than `admin` of the namespace, give it a Role of your own and bind that (check the options of `flux create tenant --help` for your version).

```sh
flux create tenant team-a --with-namespace=team-a
kubectl -n team-a get serviceaccount,rolebinding
```

## Where the tenant's Flux objects live

The tenant's `GitRepository` and Flux `Kustomization` go in the tenant namespace. Because they are in `team-a`, the Secret they use must be in `team-a` too: a `secretRef` in a source always means the same namespace. A tenant therefore keeps its own credentials, and a leaked token reaches one repository, not the whole cluster.

```sh
flux create secret git fleet-auth -n team-a \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password
flux create source git fleet -n team-a \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git --branch=main --secret-ref=fleet-auth
```

## Platform team versus tenant

| Owner | Owns | Namespace |
| --- | --- | --- |
| Platform team | The controllers, the tenant definitions, shared sources | `flux-system` |
| Tenant | Its sources, its Kustomizations, its workloads | `team-a` |

Keep the tenant definitions in the platform repository, so that giving a team access is a reviewed commit.

## Common pitfalls

- Giving the tenant `cluster-admin` through a ClusterRoleBinding. That is the whole cluster.
- Putting a tenant's Secret in `flux-system` and referencing it from another namespace. It does not work, and copying the credentials there widens who can read them.
- Treating the label as a security control. It helps queries; the RoleBinding is the control.
