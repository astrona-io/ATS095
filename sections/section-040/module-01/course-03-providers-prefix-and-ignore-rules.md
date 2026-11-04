# Providers, Prefix And Ignore Rules

A bucket often holds more than one cluster needs: other environments, build output, drafts. The `Bucket` has fields to choose the server type, to list only part of the bucket, and to leave files out. This part shows each one, then ends with a graded lab that scopes a shared bucket to one environment.

## The provider decides how Flux signs in

`spec.provider` has four values. The default, `generic`, is any S3-compatible server and reads the Secret with `accesskey` and `secretkey`. `aws` talks to Amazon S3 and can use the identity of the pod or a service account, so no key is needed. `gcp` talks to Google Cloud Storage and reads a `serviceaccount` key from the Secret or uses workload identity. `azure` talks to Azure Blob Storage and reads a `accountKey`, a SAS token or a client secret from the Secret, or uses workload identity. For the cloud providers, `serviceAccountName` names a service account in the namespace of the `Bucket` that carries the cloud identity. Reading this list is enough here: the playground has only the generic server.

Three more fields belong to the connection. `region` names the region of the bucket. `certSecretRef` names a Secret with a private CA for a server with its own certificate. `proxySecretRef` sends the requests through a proxy. They work like the same fields of an `OCIRepository`. For the AWS provider, `spec.sts` can exchange credentials with a security token service. Use that only if your platform requires it.

## Prefix: list less

A bucket has no folders; it has object keys, and a key such as `staging/deployment.yaml` only looks like a path. `spec.prefix` tells source-controller to list only keys that start with the prefix. The filter runs on the server, so objects outside the prefix are never listed, downloaded or part of the revision. Create a second bucket in the playground to see it:

<!-- astrona:playground:renew -->

```sh
kubectl -n s3 exec deploy/s3-client -- aws s3 mb s3://releases
for key in staging/deployment.yaml prod/deployment.yaml; do
  kubectl -n s3 exec deploy/s3-client -- aws s3 cp s3://podinfo/deployment.yaml - \
    | kubectl -n s3 exec -i deploy/s3-client -- aws s3 cp - s3://releases/$key
done
```

The first command creates a second bucket, `releases`, and the loop copies the deployment into two folders of it. This part continues from the Secret `s3-credentials` of the first part. Now create a `Bucket` for the whole bucket and one for the prefix, and compare:

```sh
kubectl apply -f - <<'EOF'
apiVersion: source.toolkit.fluxcd.io/v1
kind: Bucket
metadata:
  name: releases-all
  namespace: flux-system
spec:
  interval: 30m
  bucketName: releases
  endpoint: s3.s3.svc.cluster.local:9000
  insecure: true
  secretRef:
    name: s3-credentials
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: Bucket
metadata:
  name: releases-staging
  namespace: flux-system
spec:
  interval: 30m
  bucketName: releases
  prefix: staging/
  endpoint: s3.s3.svc.cluster.local:9000
  insecure: true
  secretRef:
    name: s3-credentials
EOF
flux get sources bucket
```

The two sources have different revisions, because the revision is computed from the keys and ETags that each one listed. Now change `prod/deployment.yaml` and request a reconcile of both:

```sh
kubectl -n s3 exec deploy/s3-client -- aws s3 cp s3://releases/prod/deployment.yaml - \
  | sed 's/replicas: [0-9]*/replicas: 9/' | kubectl -n s3 exec -i deploy/s3-client -- aws s3 cp - s3://releases/prod/deployment.yaml
flux reconcile source bucket releases-all
flux reconcile source bucket releases-staging
flux get sources bucket
```

`releases-all` has a new revision, and `releases-staging` has the same one as before. That is the use of a prefix: a change in another environment does not cause a new artifact, and nothing downstream re-applies. The artifact keeps the full key, so the staging files are in the folder `staging/` of the artifact, and a Flux `Kustomization` reads them with `path: ./staging`.

## Ignore: leave files out

`spec.ignore` takes patterns in `.gitignore` syntax. A matching key is not part of the artifact and not part of the revision. The bucket root may also hold a file `.sourceignore` with patterns. source-controller reads it first and adds the patterns of `spec.ignore` after it, so a pattern in the spec wins. Hide the drafts:

```yaml
spec:
  prefix: staging/
  ignore: |
    draft/
    *.bak
```

The default rules also exclude the usual version control folders and a few binary types, so those never need an entry. Remember that ignore filters **after** listing: the keys are still listed from the server, so a huge prefix costs listing time even if all of it is ignored. Use `prefix` to make the listing small, and `ignore` for the exceptions inside it.

Why does ignore matter for correctness? A Flux `Kustomization` without a `kustomization.yaml` in its folder builds one from every YAML file it finds. A draft with the same resource name as the real file makes that build fail with a duplicate resource error. Leaving the draft out of the artifact is the clean fix, and the lab tests exactly that.

## Common pitfalls

> [!WARNING]
> - **A prefix without a trailing slash.** `staging` also matches `staging-old/`. Use `staging/`.
> - **Forgetting that the path keeps the prefix.** With `prefix: staging/`, the Flux `Kustomization` path is `./staging`, not `./`.
> - **Using ignore as a security boundary.** The ignored objects are still listed from the server, and the credentials can still read them. Restrict the key on the server for a real boundary.
> - **Expecting a pattern to be a regular expression.** Ignore rules use `.gitignore` syntax, so `*.bak` and `draft/` work and `.*\.bak$` does not.

## Your mission: Scope A Bucket With A Prefix And Ignore Rules

The graded lab gives you a shared bucket with `staging/` and `prod/`, a `Bucket` that reads everything, and a Flux `Kustomization` that fails because of a draft. Scope the source to the staging environment and get it applied.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-095-playground-040-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-040/module-01/labs/lab-02
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-02
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-095-lab-040-01-02
astrona start ats-095-playground-040-01
```
