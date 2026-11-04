# Solution

## Step 1: Read the state

```sh
flux get sources oci
flux events --for OCIRepository/podinfo
```

The source is not ready. The message names a failed pull from the address. Look at the `url`: the repository is `podinfo-manifest`, and the registry holds `podinfo-manifests`.

## Step 2: Fix the repository name

```sh
kubectl -n flux-system patch ocirepository podinfo --type=merge -p '{"spec":{"url":"oci://registry.localtest.me:5001/podinfo-manifests"}}'
flux reconcile source oci podinfo
flux events --for OCIRepository/podinfo
```

The message changes: the registry speaks plain HTTP and the client expects HTTPS.

## Step 3: Allow the HTTP registry

```sh
kubectl -n flux-system patch ocirepository podinfo --type=merge -p '{"spec":{"insecure":true}}'
flux reconcile source oci podinfo
```

The message changes again: the tag `1.1` is not found.

## Step 4: Use the tag that exists

```sh
kubectl -n flux-system patch ocirepository podinfo --type=merge -p '{"spec":{"ref":{"tag":"1.1.0"}}}'
flux reconcile source oci podinfo
flux reconcile kustomization podinfo
```

## Step 5: Check

```sh
flux get sources oci
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

Then run `astrona submit`.
