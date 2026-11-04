# Exact Git References With ref.name

A branch name and a tag cover most cases. Git also has other references: pull requests, merge requests and notes. This part shows the full reference name field, explains which `ref` field wins when several are set, and ends with the graded lab.

## Full reference names

`spec.ref.name` takes a complete Git reference, such as `refs/heads/main`, `refs/tags/v1.1.0`, `refs/pull/420/head` or `refs/merge-requests/1/head`. It makes a `GitRepository` follow a pull request, which is useful for a preview environment. Follow the tag `v1.1.0` this way:

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"ref":{"name":"refs/tags/v1.1.0"}}}'
flux reconcile source git fleet
flux get sources git
kubectl -n podinfo get deployment podinfo -o jsonpath='{.spec.replicas}{"\n"}'
```

The revision of `fleet` now starts with the reference name and ends with the commit hash of the tag, and the Deployment runs 2 replicas, the number the tag `v1.1.0` asks for. The field `branch: main` is still in the spec. It has no effect, because `name` wins over `branch`.

## Which field wins

The order is `branch`, `tag`, `semver`, `name`, `commit`, and a later field overrides an earlier one. This is the most common reason a branch seems to be ignored. Look at the spec and the revision together:

```sh
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.ref}{"\n"}{.status.artifact.revision}{"\n"}'
```

The spec shows both `branch` and `name`, and the revision follows `name`. Now point `name` at a reference that does not exist:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"ref":{"name":"refs/heads/release"}}}'
flux reconcile source git fleet
flux events --for GitRepository/fleet
```

The `GitRepository` is not ready and the message says the reference was not found, although the branch `main` exists. Remove the field to go back to the branch. A merge patch with `null` deletes a key:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"ref":{"name":null}}}'
flux reconcile source git fleet
```

## Provider limits

Some providers cannot fetch every reference. Azure DevOps and AWS CodeCommit cannot fetch the head of a pull request. Check the provider before you build a preview workflow on `refs/pull/<id>/head`.

You can now fetch an exact reference and predict which field wins. That is enough to repair a `GitRepository` whose sparse checkout and reference are both wrong.

## Common pitfalls

> [!WARNING]
> - **Leaving an old `name` in place.** It silently overrides `branch`.
> - **A short reference.** `name` needs the full form, `refs/heads/main`, not `main`.
> - **Expecting a pull request on every provider.** Some providers refuse it.
> - **Pinning `commit` to hide a range problem.** `commit` wins over everything, and the source stops following new commits.

## Your mission: Fetch The Right Directories From The Right Reference

You can now limit an artifact with `sparseCheckout` and control the reference with `ref.name`. The graded lab gives you a `GitRepository` that fetches the wrong directory from the wrong reference, and asks you to fix it in place so the Flux `Kustomization` applies.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-095-playground-010-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-010/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-095-lab-010-03
astrona start ats-095-playground-010-03
```
