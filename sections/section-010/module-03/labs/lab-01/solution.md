# Solution

## Step 1: Read the state

```sh
flux get sources git
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.ref}{"\n"}{.spec.sparseCheckout}{"\n"}'
flux events --for GitRepository/fleet
```

The spec holds both `branch: main` and `name: refs/heads/release`. The field `name` wins over `branch`, and that reference does not exist, so `fleet` cannot fetch. Check each cause one at a time.

## Step 2: Remove ref.name

A merge patch with `null` deletes the key:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"ref":{"name":null}}}'
flux reconcile source git fleet
```

`fleet` is now Ready on `main`, but the Flux `Kustomization` still fails with a message that `./apps/podinfo` was not found. The artifact holds only `clusters`.

## Step 3: Add apps to the sparse checkout

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"sparseCheckout":["apps","clusters"]}}'
flux reconcile source git fleet
flux reconcile kustomization podinfo
```

## Step 4: Check

```sh
flux get sources git
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

Then run `astrona submit`.
