# Solution: Deliver From A Bucket And Trigger A Reconcile

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the `Bucket` reads the right bucket over HTTP every 30 minutes and is `Ready`; the Secret holds `accesskey` and `secretkey`; and the bucket's 3-replica change is applied from the `Bucket`'s current revision.

## Step 1: Create the Secret

The `generic` provider reads exactly the keys `accesskey` and `secretkey`:

```sh
kubectl -n flux-system create secret generic s3-credentials \
  --from-literal=accesskey=flux-s3 \
  --from-literal=secretkey=flux-s3-secret
```

## Step 2: Create the Bucket and the Flux Kustomization

Save this as `bucket-podinfo.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: Bucket
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 30m
  provider: generic
  bucketName: podinfo
  endpoint: s3.s3.svc.cluster.local:9000
  insecure: true
  secretRef:
    name: s3-credentials
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 30m
  path: ./
  prune: true
  wait: true
  timeout: 2m
  sourceRef:
    kind: Bucket
    name: podinfo
```

Apply it:

```sh
kubectl apply -f bucket-podinfo.yaml
```

Then check the result:

```sh
flux get sources bucket
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

The `Bucket` and the Flux `Kustomization` are `Ready` on the same `sha256:` revision, and podinfo runs 2 replicas.

## Step 3: Upload the change

Download `deployment.yaml`, change the replicas, and upload it:

```sh
kubectl -n s3 exec deploy/s3-client -- aws s3 cp s3://podinfo/deployment.yaml - > deployment.yaml
sed -i.bak 's/replicas: 2/replicas: 3/' deployment.yaml
kubectl -n s3 exec -i deploy/s3-client -- aws s3 cp - s3://podinfo/deployment.yaml < deployment.yaml
```

The cluster still runs 2 replicas: the next scheduled check is up to 30 minutes away.

## Step 4: Request the reconciliation

Ask source-controller to fetch now and kustomize-controller to apply the result, without touching the interval:

```sh
flux reconcile source bucket podinfo
flux reconcile kustomization podinfo
flux get sources bucket
kubectl -n podinfo get deployment podinfo
```

The `Bucket` has a new revision, and podinfo runs 3 ready replicas. Setting the annotation `reconcile.fluxcd.io/requestedAt` with `kubectl annotate --overwrite` gives the same result; it is what a build job would do.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `interval: 1m` on the `Bucket` | The change arrives, but the source checks 30 times more often than allowed; the grader checks `30m` |
| `kubectl scale deployment podinfo --replicas=3` | The bucket and the cluster agree only by chance, and Flux puts back whatever the bucket says |
| Secret keys `access_key` and `secret_key` | The `generic` provider ignores them, and the server refuses the request |
| `flux reconcile kustomization podinfo` alone | Applies the artifact the `Bucket` already had; add `--with-source` or reconcile the source first |
