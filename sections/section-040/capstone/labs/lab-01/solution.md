# Solution: Repair A Bucket Source

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the `Bucket` reads the bucket `podinfo` over HTTP and is `Ready`, the Secret has the right keys, the Flux `Kustomization` applies the bucket root on the current revision with 2 ready replicas, and the `Bucket` and the Flux `Kustomization` were fixed in place.

## Step 1: Read what the source reports

```sh
flux get sources bucket
flux events --for Bucket/podinfo
kubectl -n flux-system get bucket podinfo -o jsonpath='{.spec}{"\n"}'
kubectl -n s3 exec deploy/s3-client -- aws s3 ls
```

The `Bucket` is not `Ready`, and its spec shows two faults. `bucketName` is `podinfo-manifests`, but the server only has a bucket named `podinfo`. And there is no `insecure: true`, so source-controller tries HTTPS against a server that only speaks plain HTTP. Which of the two the events name first depends on the order of the checks, so fix both.

## Step 2: Read the Secret

```sh
kubectl -n flux-system get secret s3-credentials -o jsonpath='{.data}' | jq 'keys'
```

The keys are `access_key` and `secret_key`. The `generic` provider reads exactly `accesskey` and `secretkey`, so with this Secret source-controller sends no credentials at all. That is the third fault.

## Step 3: Fix the Secret and the Bucket

Replace the Secret with the right key names, then fix the `Bucket` in place:

```sh
kubectl -n flux-system delete secret s3-credentials
kubectl -n flux-system create secret generic s3-credentials \
  --from-literal=accesskey=flux-s3 \
  --from-literal=secretkey=flux-s3-secret
kubectl -n flux-system patch bucket podinfo --type=merge -p '{"spec":{"bucketName":"podinfo","insecure":true}}'
flux reconcile source bucket podinfo
flux get sources bucket
```

The `Bucket` is `Ready` with a `sha256:` revision.

## Step 4: Read the Flux Kustomization

The source works now, but the namespace `podinfo` still does not exist:

```sh
flux get kustomizations
kubectl -n flux-system get kustomization podinfo -o jsonpath='{.spec.path}{"\n"}'
```

The path is `./podinfo`, but the bucket holds its manifests at the root. There is no folder `podinfo` inside the artifact, so kustomize-controller cannot build anything. That is the fourth fault.

## Step 5: Fix the path

```sh
kubectl -n flux-system patch kustomization podinfo --type=merge -p '{"spec":{"path":"./"}}'
flux reconcile kustomization podinfo
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

The Flux `Kustomization` is `Ready` on the `Bucket`'s revision, and podinfo runs 2 ready replicas.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create a bucket named `podinfo-manifests` and copy the files | Changes the storage, which the task forbids, and the build job keeps writing to `podinfo` |
| Move the files into a folder `podinfo` in the bucket | Same, and the build job's next upload breaks it again |
| Delete and recreate the `Bucket` and the Flux `Kustomization` | The task asks for a repair in place, and the grader checks it |
| Add `accesskey` and `secretkey` but keep the old keys | Works, but leaves two copies of the credentials in one Secret |
