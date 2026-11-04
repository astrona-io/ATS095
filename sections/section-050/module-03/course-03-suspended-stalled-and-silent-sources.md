# Suspended, Stalled And Silent Sources

Some sources show no error at all.

## Suspended

A source with `spec.suspend: true` is skipped. Its status shows the values from the last run, the `READY` column still reads `True` if it was Ready, and the `SUSPENDED` column shows `True`. Nothing is fetched, so a new commit never arrives:

<!-- astrona:playground:renew -->

```sh
flux suspend source git fleet
flux get sources git
flux resume source git fleet
```

A source that was suspended before its first fetch has no artifact at all, and every consumer waits. Look at the `SUSPENDED` column whenever "nothing happens".

## Stalled

`Stalled` means the controller decided that retrying will not help until the spec changes. An invalid field value, an unsupported option and a missing mandatory Secret key can do this. The condition `Stalled` is `True` and `Ready` is `False`. Fix the spec; the next reconcile clears it.

## Reconciling forever

A source with `Reconciling` stuck at `True` is mid-fetch or waiting on a dependency, for example a Git source that includes another repository that is not ready. Read the message of the condition and follow the dependency.

## The consumer is the one that is stuck

A source that is `Ready` can still leave the cluster unchanged. Compare:

```sh
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.revision}{"\n"}'
kubectl -n flux-system get kustomization podinfo -o jsonpath='{.status.lastAppliedRevision}{"\n"}'
```

If the revisions differ, the problem is in the Flux `Kustomization` (a wrong `path`, a failed health check, a suspension of its own), not in the source.

## Common pitfalls

- Reading `Ready: True` on a suspended source as "up to date".
- Suspending a source to "pause a rollout" and forgetting it. Use a comment or a label to record why.
- Looking at the source when the consumer is the one that failed.

## Your mission: Fix Failing Sources

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-095-playground-050-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-050/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-050/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-095-lab-050-03
astrona start ats-095-playground-050-03
```
