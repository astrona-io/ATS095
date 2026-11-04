# Solution

## Step 1: Find the fault

```sh
flux get kustomizations
kubectl -n flux-system describe kustomization releases
```

The Kustomization fails to build `./staging`. There is no `kustomization.yaml` in the folder, so kustomize-controller builds one from every YAML file under it, and `staging/draft/deployment.yaml` defines the same Deployment as `staging/deployment.yaml`. The build stops with a message that a resource with the same id is already registered.

## Step 2: Scope the Bucket

A prefix is applied while the objects are listed, and `ignore` uses `.gitignore` syntax. Patch both:

```sh
kubectl -n flux-system patch bucket releases --type=merge -p '{"spec":{"prefix":"staging/","ignore":"draft/\n"}}'
```

## Step 3: Fetch and apply

```sh
flux reconcile source bucket releases
flux reconcile kustomization releases
```

The object keys keep the prefix in the artifact, so the path `./staging` of the Kustomization is still correct.

## Step 4: Check

```sh
flux get sources bucket
flux get kustomizations
kubectl -n podinfo-staging get deployment podinfo
kubectl get namespace podinfo-prod
```

The last command reports that the namespace does not exist. Then run `astrona submit`.
