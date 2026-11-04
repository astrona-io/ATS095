# Summary

A tenant brings its own source and applies it as its own ServiceAccount.

## What you learned

A tenant is a namespace, a ServiceAccount and a RoleBinding limited to that namespace; `flux create tenant` writes them. The tenant's `GitRepository`, its credentials Secret and its Flux `Kustomization` live in the tenant namespace, because a `secretRef` is always in the namespace of its object. `--no-cross-namespace-refs=true` on kustomize-controller, helm-controller and notification-controller makes a reference to another namespace an error, so a tenant cannot use a source it does not own. `spec.serviceAccountName` makes kustomize-controller apply as the tenant account, so RBAC limits what the repository can create, and `--default-service-account` makes that the default. `kubectl auth can-i --as=system:serviceaccount:<ns>:<name>` shows the confinement. Flux does not restrict `spec.url`, the egress of source-controller or the readability of artifacts inside `flux-system`; add admission and network policies. The key facts to remember are these:

- Source and Secret in the tenant namespace; Kustomization with `serviceAccountName`.
- The flag blocks references; it is not removed to make things work.
- A ServiceAccount bound to `cluster-admin` removes the protection.
- Flux has no allow-list for source URLs.

<!-- astrona:playground:destroy -->
