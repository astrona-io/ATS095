# Solution: Fix A HelmChart That Builds From Git

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the `GitRepository` is `Ready` on the branch `master`, the `HelmChart` is `Ready` and built from `charts/podinfo`, and `reconcileStrategy` is `Revision` with both objects fixed in place.

## Step 1: Fix the source first

A `HelmChart` cannot build until its source is ready, so start there:

```sh
flux get sources git
flux events --for GitRepository/podinfo-git
```

The `GitRepository` is not ready, and the message says that the branch `main` cannot be found. The repository's default branch is `master`:

```sh
kubectl -n flux-system patch gitrepository podinfo-git --type=merge -p '{"spec":{"ref":{"branch":"master"}}}'
flux reconcile source git podinfo-git
flux get sources git
```

The `GitRepository` is `Ready` with a revision that starts with `master@`.

## Step 2: Fix the chart path

```sh
flux get sources chart
flux events --for HelmChart/podinfo-git
```

The message says the chart cannot be found at the path `./chart/podinfo`. The directory is `charts/podinfo`:

```sh
kubectl -n flux-system patch helmchart podinfo-git --type=merge -p '{"spec":{"chart":"./charts/podinfo"}}'
flux reconcile source chart podinfo-git --with-source
flux get sources chart
```

## Step 3: Rebuild on every commit

```sh
kubectl -n flux-system patch helmchart podinfo-git --type=merge -p '{"spec":{"reconcileStrategy":"Revision"}}'
flux reconcile source chart podinfo-git --with-source
flux get sources chart
```

The revision of the `HelmChart` now contains a plus sign and the start of the commit hash.

## Step 4: Submit

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Set `spec.version` on the `HelmChart` | The field is ignored for a Git source |
| Pin a `commit` in the `GitRepository` | The chart no longer follows new commits |
| Delete and recreate the objects | The grader checks the object identity |
