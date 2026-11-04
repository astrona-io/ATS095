# Cross-Namespace References And The Flag

Many Flux objects can point at an object in another namespace. A Flux `Kustomization` has `spec.sourceRef.namespace`, and a `HelmRelease` can do the same with a chart source. That is handy for shared sources, and it is also how one team could use another team's source or credentials.

## The flag

The controllers that follow such references have a flag:

```text
--no-cross-namespace-refs=true
```

With it on, an object that points at another namespace gets an error and applies nothing. The flag exists on kustomize-controller, helm-controller, notification-controller and the image automation controllers, not on source-controller: a `secretRef` of a source is always in the namespace of the source, and a source has no field that points at another namespace.

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system get deployment kustomize-controller \
  -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}'
```

## What happens when it is on

A Flux `Kustomization` in `team-a` with `sourceRef.namespace: flux-system` is refused. Its `Ready` condition is `False` with a message that says a cross-namespace reference is not allowed. The reference is never followed, so the tenant cannot use a source it does not own.

```sh
kubectl -n team-a describe kustomization team-a-apps
```

## The fix for the tenant

The tenant brings its own source in its own namespace, as in the previous part, and points at it:

```sh
kubectl -n team-a patch kustomization team-a-apps --type=merge -p \
  '{"spec":{"sourceRef":{"kind":"GitRepository","name":"fleet","namespace":"team-a"}}}'
```

A reference with the tenant's own namespace (or none) is fine.

## When a shared source is wanted

Sometimes many tenants should read one shared repository, for example a base catalogue. With the flag on you cannot do it by reference. Options: give each tenant its own `GitRepository` for the same URL, or run the platform team's Kustomization (with its own rights) to apply the shared part, and let tenants build on top of it.

## Common pitfalls

- Turning the flag off to "make it work". It removes the isolation for every tenant.
- Looking for the flag on source-controller. It is on the controllers that follow references.
- Forgetting that a flag change rolls the controller and re-reconciles everything it owns.
