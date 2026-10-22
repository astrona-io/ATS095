# Solution: Pin A Release Line And Trim The Artifact

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: `fleet` follows a semver range and is at `v1.2.0`, its artifact has no `docs` folder, `podinfo` runs release `v1.2.0`, and both Flux objects were fixed in place.

## Step 1: Find which release the cluster follows

Start with the source, because the Flux `Kustomization` can only apply what the source fetched:

```sh
flux get sources git
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.ref}{"\n"}'
```

The revision starts with `v2.0.0@sha1:`, and the reference is `semver: ">=1.0.0"`. The range has no upper bound, so `v2.0.0` matched as soon as it was tagged.

## Step 2: Find why podinfo is not healthy

Now read what the Flux `Kustomization` reports, and what the pods do:

```sh
flux get kustomizations
flux events --for Kustomization/podinfo
kubectl -n podinfo get pods
```

The Flux `Kustomization` `podinfo` is not `Ready`: it applied release `v2.0.0`, then its health check timed out. The new pods cannot pull their image, because release `v2.0.0` asks for `ghcr.io/stefanprodan/podinfo:9.9.9`, which does not exist. The fix is not in the Flux `Kustomization`; it is in the range that let this release in.

## Step 3: Restrict the range and trim the artifact

Give the range an upper bound, and leave `docs` out with `spec.ignore`. A `.sourceignore` file would not help here: it only affects commits that contain it, and you may not add a release. Because `spec.ignore` replaces the default rules, the rules below repeat `.git/`. Save this as `gitrepository-fleet.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: fleet
  namespace: flux-system
spec:
  interval: 1m
  url: http://gitea.localtest.me:3000/gitops/fleet.git
  ref:
    semver: ">=1.0.0 <2.0.0"
  secretRef:
    name: fleet-auth
  ignore: |
    .git/
    /docs/
```

Apply it:

```sh
kubectl apply -f gitrepository-fleet.yaml
```

Then check the result:

```sh
flux reconcile source git fleet
flux get sources git
```

The revision is now `v1.2.0@sha1:` and the commit of that tag: `v1.2.0` is the highest tag below `2.0.0`.

## Step 4: Confirm the artifact holds no docs

Read the file list of the artifact from a short-lived pod in `flux-system`, the only namespace the Flux network policies allow:

```sh
ARTIFACT_URL="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.url}')"
kubectl -n flux-system run artifact-reader --rm -i --restart=Never --quiet \
  --image=nicolaka/netshoot:v0.13 -- sh -c "curl -s '$ARTIFACT_URL' | tar -tzf -"
```

The list holds the files under `apps/podinfo` and `clusters/kind`, and nothing under `docs`.

## Step 5: Apply release v1.2.0

Ask kustomize-controller to apply the new artifact now, then check the workload:

```sh
flux reconcile kustomization podinfo
flux get kustomizations
kubectl -n podinfo get deployment podinfo -o jsonpath='{.spec.template.spec.containers[0].image}{"  "}{.status.readyReplicas}{"\n"}'
```

The Flux `Kustomization` is `Ready` on the `v1.2.0` revision, and the Deployment runs `ghcr.io/stefanprodan/podinfo:6.15.0` with 2 ready replicas. Flux replaced the failing pods with the image of the 1.x release.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `ref.tag: v1.2.0` | Works today, but the next 1.x release never arrives; the task asks for a range |
| `ref.commit` of `v1.2.0` | Same problem, and the commit hides which release the cluster runs |
| Delete the tag `v2.0.0` | Changes the repository, which the task forbids, and the next major release breaks the cluster again |
| `.sourceignore` on `main` | Release `v1.2.0` does not contain it, so the artifact keeps `docs` |
| Suspend the Flux `Kustomization` | Hides the failure and stops every future release |
