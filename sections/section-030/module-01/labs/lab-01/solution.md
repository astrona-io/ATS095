# Solution: Make A Helm Chart Resolve

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the `HelmChart` `podinfo` is `Ready` on a 6.x version from the `HelmRepository` `podinfo`, the type of that `HelmRepository` matches its address, and both objects were fixed in place.

## Step 1: Follow the chart back to its repository

Start with the object that should work, then the one it depends on:

```sh
flux get sources chart
flux events --for HelmChart/podinfo
flux get sources helm
kubectl -n flux-system get helmrepository podinfo -o jsonpath='{.spec}{"\n"}'
```

The `HelmChart` is not `Ready`, and its events point at its source. The `HelmRepository` `podinfo` has no `type`, so it uses the default type, which downloads an `index.yaml` over HTTP. But its address is `oci://ghcr.io/stefanprodan/charts`, a registry, which has no `index.yaml`. The type and the address do not match.

## Step 2: Make the type and the address match

There are two correct fixes, and the task allows either. The first keeps the default type and points it at the HTTP repository:

```sh
kubectl -n flux-system patch helmrepository podinfo --type=merge -p \
  '{"spec":{"url":"https://stefanprodan.github.io/podinfo"}}'
```

The second keeps the registry address and sets `type: oci` instead:

```sh
kubectl -n flux-system patch helmrepository podinfo --type=merge -p '{"spec":{"type":"oci"}}'
```

This walkthrough uses the first. With it, the `HelmRepository` itself reports `Ready`, which makes later problems easier to see.

## Step 3: Check the chart

```sh
flux reconcile source helm podinfo
flux reconcile source chart podinfo
flux get sources helm
flux get sources chart
```

The `HelmRepository` is `Ready` with the revision of its stored index, and the `HelmChart` is `Ready` on a chart version that starts with `6.`.

## Step 4: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Change the `HelmChart` version to `*` | The range was never the problem; the chart still cannot be fetched |
| Create a second `HelmRepository` and point the `HelmChart` at it | Changes the `HelmChart`, which the task forbids, and leaves a broken object behind |
| Delete and recreate the `HelmRepository` with the same spec | The fault comes back with it |
