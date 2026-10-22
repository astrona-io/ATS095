# Solution: Follow The Newest 1.x Release From A Registry

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the `OCIRepository` follows a semver range and is at `1.3.0`, the registry holds `1.3.0` next to the other releases, and the Flux `Kustomization` applied `1.3.0`, so `podinfo` runs 2 replicas.

## Step 1: Look at the current state

```sh
flux get sources oci
flux list artifacts oci://registry.localtest.me:5001/podinfo-manifests --insecure-registry
kubectl -n podinfo get deployment podinfo
```

The `OCIRepository` is at `1.0.0@sha256:`, and the Deployment runs 1 replica. The registry lists four releases.

## Step 2: Follow the newest stable 1.x release

Replace the whole `ref` with a range that stops below `2.0.0`. A plain range skips the release candidate on its own:

```sh
kubectl -n flux-system patch ocirepository podinfo --type=json -p \
  '[{"op":"replace","path":"/spec/ref","value":{"semver":">=1.0.0 <2.0.0"}}]'
flux reconcile kustomization podinfo --with-source
flux get sources oci
```

The revision moves to `1.1.0@sha256:`, the highest stable 1.x release so far, and the Deployment goes to 3 replicas.

## Step 3: Push release 1.3.0 from Git

Clone the repository, keep the commit of `main`, and push `apps/podinfo` with its source and revision:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
flux push artifact oci://registry.localtest.me:5001/podinfo-manifests:1.3.0 \
  --path=./apps/podinfo \
  --source="http://gitea.localtest.me:3000/gitops/fleet.git" \
  --revision="main@sha1:$(git rev-parse HEAD)" \
  --insecure-registry
```

The command reports the pushed artifact and its digest.

## Step 4: Let the cluster take it

source-controller finds the new tag within its interval of one minute. Ask for it now:

```sh
flux reconcile kustomization podinfo --with-source
flux get sources oci
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

The `OCIRepository` and the Flux `Kustomization` are both `Ready` on `1.3.0@sha256:`, and the Deployment runs 2 replicas, the value on `main`.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `ref.tag: 1.3.0` | The cluster runs `1.3.0`, but the next 1.x release never arrives |
| `semver: ">=1.0.0"` | `2.0.0` is the highest match, and the cluster jumps a major version |
| `semver: ">=1.0.0-0 <2.0.0"` | The range lets pre-releases in; with a newer release candidate, the cluster would run it |
| Pin the digest of `1.3.0` | The digest overrides the range, and new releases stop |
| Delete `2.0.0` from the registry | Removes a release other clusters may need; the range already excludes it |
