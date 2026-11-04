# Solution: Find Why A HelmChart Is Not Ready

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-02` after a step tells you which checks pass.

The grader checks three things: the `HelmChart` `podinfo` is `Ready` on a 6.x version from the `HelmRepository` `podinfo`, the `HelmRepository` is unchanged and `Ready`, and both objects were fixed in place.

## Step 1: Read the message

```sh
flux get sources helm
flux get sources chart
flux events --for HelmChart/podinfo
kubectl -n flux-system get helmchart podinfo -o jsonpath='{range .status.conditions[*]}{.type}{"\t"}{.status}{"\t"}{.reason}{"\n"}{end}'
```

The `HelmRepository` is `Ready`, so the fault is in the `HelmChart`. Its message names a chart that the repository does not publish or a version that no chart matches. Read the spec of the object to see both fields:

```sh
kubectl -n flux-system get helmchart podinfo -o jsonpath='{.spec.chart}{"  "}{.spec.version}{"\n"}'
```

## Step 2: Fix one field and check

The chart name is `podinf`, which is misspelled. Fix it first and look at the message again:

```sh
kubectl -n flux-system patch helmchart podinfo --type=merge -p '{"spec":{"chart":"podinfo"}}'
flux reconcile source chart podinfo --with-source
flux get sources chart
```

The chart name is found now, and the message changes to the second fault: the range `7.x` has no matching version.

## Step 3: Fix the second field

```sh
kubectl -n flux-system patch helmchart podinfo --type=merge -p '{"spec":{"version":"6.x"}}'
flux reconcile source chart podinfo --with-source
flux get sources chart
```

The `HelmChart` is `Ready` on a chart version that starts with `6.`.

## Step 4: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-02
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Change `version` to `*` | It may resolve a version outside 6.x, and the task asks for 6.x |
| Edit the `HelmRepository` | It works; the grader checks that it is unchanged |
| Delete and recreate the `HelmChart` | The grader checks the object identity |
