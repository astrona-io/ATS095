# Control Access To Sources In A Multi-Tenant Cluster

In a shared cluster, several teams own their own namespaces and their own repositories. If Flux runs everything with the rights of the controllers, one team's Git repository can create objects in another team's namespace, or in none at all. Multi-tenancy in Flux is a set of small, explicit choices that stop that.

The first choice is where the source lives. The second is who may point at it. The third is which identity applies what it fetches. Each choice maps to one field or one flag, and together they keep a team inside its namespace.

Keep one sentence in mind: **a tenant brings its own source and applies it with its own identity.** A source in the namespace of the tenant, and `serviceAccountName` on its Kustomization, are the two fields that say so.

The module has four parts. **Tenants And Namespaces** defines a tenant and creates one with the CLI. **Cross-Namespace References And The Flag** shows what `--no-cross-namespace-refs` blocks and why. **Impersonation With serviceAccountName** makes a tenant apply with its own rights; a graded lab follows it. **What Flux Does Not Restrict** names the limits and the other layers you add.

## Learning objectives

After this module you can:

- Describe a tenant as a namespace, a ServiceAccount and a RoleBinding.
- Create a tenant with `flux create tenant`.
- Explain what `--no-cross-namespace-refs` blocks, and which controllers have the flag.
- Give a tenant its own `GitRepository` and credentials Secret.
- Use `spec.serviceAccountName` so a Flux `Kustomization` applies as the tenant.
- Check the confinement with `kubectl auth can-i --as`.

## Before you start

You need `GitRepository` and Flux `Kustomization` from earlier sections and the basics of Kubernetes RBAC (Role, ClusterRole, RoleBinding, ServiceAccount). Your playground is a single-node `kind` cluster with **Flux v2.9.6**, Gitea with the lab-only user `gitops` and the password `gitops-password`, and the repositories `gitops/fleet` and `gitops/platform`. The `GitRepository` `fleet` follows `main` with the Secret `fleet-auth`, and the Flux `Kustomization` `podinfo` applies `./apps/podinfo`.

The Git server answers at `http://gitea.localtest.me:3000`. Inside the cluster this name already works. On your machine it works while a port-forward runs, so open a second terminal and leave this running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
