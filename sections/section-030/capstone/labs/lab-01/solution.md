# Solution: Make A HelmRelease's Chart Resolve

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the `HelmRepository` is `Ready` on the right address, the `HelmChart` behind the release resolved a 6.x version from it, the `HelmRelease` is `Ready` with podinfo running, and both objects were fixed in place.

## Step 1: Read the HelmRelease

```sh
flux get helmreleases
kubectl -n flux-system get helmrelease podinfo -o jsonpath='{.spec.chart.spec}{"\n"}'
```

The `HelmRelease` is not `Ready`. Its chart spec asks for the chart `podinfo`, version `7.x`, from a `HelmRepository` named `charts`. There is no `HelmRepository` named `charts`, only `podinfo`. That is the first fault, and the one the `HelmRelease` reports.

## Step 2: Read the HelmRepository

```sh
flux get sources helm
flux events --for HelmRepository/podinfo
```

The `HelmRepository` `podinfo` is not `Ready` either: its address is `https://stefanprodan.github.io/podinf`, with a letter missing, so source-controller cannot download an index from it. That is the second fault. Fix it first, because the `HelmRelease` will need it:

```sh
kubectl -n flux-system patch helmrepository podinfo --type=merge -p \
  '{"spec":{"url":"https://stefanprodan.github.io/podinfo"}}'
flux reconcile source helm podinfo
flux get sources helm
```

The `HelmRepository` is `Ready` with the revision of its index.

## Step 3: Fix the chart spec of the HelmRelease

Point the `HelmRelease` at `podinfo`. The range `7.x` is the third fault: the chart's current major version is 6, so `7.x` matches nothing. Change both fields in the `HelmRelease`, not in the `HelmChart`, because helm-controller writes the `HelmChart` from the `HelmRelease`:

```sh
kubectl -n flux-system patch helmrelease podinfo --type=merge -p \
  '{"spec":{"chart":{"spec":{"version":"6.x","sourceRef":{"kind":"HelmRepository","name":"podinfo"}}}}}'
flux reconcile helmrelease podinfo --with-source
```

`--with-source` makes the `flux` tool ask source-controller to resolve the chart first, then helm-controller to install it.

## Step 4: Check the whole chain

```sh
kubectl get helmcharts -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,CHART:.spec.chart,SOURCE:.spec.sourceRef.name,VERSION:.status.artifact.revision
flux get helmreleases
kubectl -n podinfo get deployment podinfo
```

The `HelmChart` behind the release reads the chart `podinfo` from the source `podinfo` and resolved a 6.x version. The `HelmRelease` is `Ready`, and the Deployment `podinfo` runs in the namespace `podinfo`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create a `HelmRepository` named `charts` | The task forbids a second repository, and you now maintain two objects for one address |
| Edit the `HelmChart` helm-controller created | helm-controller writes it back from the `HelmRelease` at the next reconcile |
| Leave out `version` | `*` installs whatever the newest major version is, including a future 7.x with breaking changes |
| `helm install` by hand | Flux does not manage that release, and the `HelmRelease` stays broken |
