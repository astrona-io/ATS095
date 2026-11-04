# Solution

## Step 1: Read the state

```sh
flux get sources oci
flux events --for OCIRepository/podinfo
```

The message says that the pull is not authorized. The `OCIRepository` has no `secretRef`, so source-controller asks the registry without credentials, and the registry answers with 401.

## Step 2: Point the source at the Secret

```sh
kubectl -n flux-system patch ocirepository podinfo --type=merge -p '{"spec":{"secretRef":{"name":"regcred"}}}'
flux reconcile source oci podinfo
flux events --for OCIRepository/podinfo
```

The message still reports an authentication failure. The Secret is used now, so the credentials in it must be wrong.

## Step 3: Replace the Secret

`flux create secret oci` writes a `dockerconfigjson` Secret. Delete the old one and create it again with the right password:

```sh
kubectl -n flux-system delete secret regcred
flux create secret oci regcred -n flux-system --url=registry.localtest.me:5001 --username=flux --password=registry-password
flux reconcile source oci podinfo
flux reconcile kustomization podinfo
```

## Step 4: Check

```sh
flux get sources oci
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

Then run `astrona submit`.
