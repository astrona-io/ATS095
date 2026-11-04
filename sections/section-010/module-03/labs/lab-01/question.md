# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Git sources, sparse checkout and references

## Scenario

A teammate tuned the `GitRepository` `fleet` in the namespace `flux-system` to make it smaller and to follow a release reference. Since then it has not delivered the application. The Flux `Kustomization` `podinfo` applies nothing. The Secret `fleet-auth` and the address are correct.

Start by reading the state:

```sh
flux get sources git
flux get kustomizations
kubectl -n flux-system get gitrepository fleet -o yaml
```

## Your task

1. Find from the conditions and the spec of `fleet` why the application is not delivered. There is more than one cause.
2. Fix each cause so that `fleet` follows the branch `main` and still uses a sparse checkout that contains the directory `apps`.
3. Confirm that the Flux `Kustomization` `podinfo` applies the revision of `fleet`.

## Constraints

- Fix `fleet` in place. Do not delete and recreate it, and do not change its `url` or its Secret.
- Do not remove `spec.sparseCheckout`.
- Do not edit the `Kustomization`.

## Success criteria

- `fleet` is Ready and its revision starts with `main@`.
- The artifact was built with a sparse checkout that includes `apps`.
- `podinfo` is Ready at the revision of `fleet` and runs 2 ready replicas.
