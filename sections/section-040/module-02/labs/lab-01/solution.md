# Solution

## Step 1: Token and Receiver

```sh
kubectl -n flux-system create secret generic webhook-token \
  --from-literal=token="$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')"
kubectl apply -f - <<'EOF'
apiVersion: notification.toolkit.fluxcd.io/v1
kind: Receiver
metadata:
  name: podinfo-upload
  namespace: flux-system
spec:
  type: generic
  secretRef:
    name: webhook-token
  resources:
    - apiVersion: source.toolkit.fluxcd.io/v1
      kind: Bucket
      name: podinfo
EOF
```

## Step 2: Wait for the path

```sh
kubectl -n flux-system wait receiver/podinfo-upload --for=condition=Ready --timeout=120s
kubectl -n flux-system get receiver podinfo-upload -o jsonpath='{.status.webhookPath}{"\n"}'
```

The path starts with `/hook/` and ends with a hash. It is the secret part of the address.

## Step 3: Upload the change

```sh
kubectl -n s3 exec deploy/s3-client -- aws s3 cp s3://podinfo/deployment.yaml - \
  | sed 's/replicas: 2/replicas: 3/' \
  | kubectl -n s3 exec -i deploy/s3-client -- aws s3 cp - s3://podinfo/deployment.yaml
```

## Step 4: Call the webhook

```sh
HOOK="$(kubectl -n flux-system get receiver podinfo-upload -o jsonpath='{.status.webhookPath}')"
kubectl -n s3 exec deploy/s3-client -- curl -fsS -X POST "http://webhook-receiver.flux-system.svc.cluster.local$HOOK"
```

The Bucket gets a reconcile request, fetches, and the Flux Kustomization applies the new revision:

```sh
flux get sources bucket
kubectl -n podinfo get deployment podinfo
```

Then run `astrona submit`.
