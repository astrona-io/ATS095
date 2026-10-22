# Choosing A Git Reference

The `GitRepository` `fleet` follows the branch `main`, so every merge reaches the cluster within a minute. Many teams want something slower for production: only commits that someone released and tagged. This part shows the five ways a `GitRepository` can pick a commit, which one wins when several are set, and how to follow a release line with a semver range.

## Read what fleet fetches now

Start with the current state. Each Flux source reports the exact content it fetched as its **revision**: a string that names the reference and the commit. Ask Flux for the Git sources:

<!-- astrona:playground:renew -->

```sh
flux get sources git
```

The row for `fleet` shows `READY` as `True` and a `REVISION` that starts with `main@sha1:`, followed by a 40-character commit hash. The part before the `@` is the reference source-controller resolved, and the part after it is the commit it fetched. Now look at the result in the cluster:

```sh
kubectl -n podinfo get deployment podinfo
```

The Deployment shows 3 replicas, because the head of `main` asks for 3. The two release tags ask for fewer, so the replica count tells you at a glance which commit the cluster runs.

## The five references

The field `spec.ref` holds the reference. It has five fields, and you normally set one of them. When you set more than one, the later field in this list wins:

| Field | Example | What source-controller fetches | Revision |
| --- | --- | --- | --- |
| `branch` | `main` | The head of the branch, checked again at every interval | `main@sha1:<commit>` |
| `tag` | `v1.0.0` | The commit the tag points to | `v1.0.0@sha1:<commit>` |
| `semver` | `>=1.0.0 <2.0.0` | The highest tag that matches the range | `v1.1.0@sha1:<commit>` |
| `name` | `refs/tags/v1.0.0` | A full Git reference, a branch or a tag | the reference and the commit |
| `commit` | `3f2a…` | Exactly that commit; can be combined with `branch` | the commit |

So `commit` beats `name`, `name` beats `semver`, `semver` beats `tag`, and `tag` beats `branch`. Without any `ref`, source-controller follows the branch `master`, which is a common reason for a source that never becomes ready on a repository that uses `main`.

The fields also differ in how often the result changes. A `branch` and a `semver` range move on their own when someone pushes a commit or a new tag. A `tag`, a `name` that points at a tag, and a `commit` stay where they are until you change the `GitRepository`.

## Follow a release line with a semver range

A semver range is a version constraint such as `>=1.0.0 <2.0.0`. Semantic versioning (semver) gives each release a number of the form major.minor.patch, and the major number changes when a release breaks something. source-controller lists the tags of the repository, keeps the ones that parse as versions and match the range, and fetches the highest. Tags with a leading `v`, such as `v1.1.0`, count as versions.

Change `fleet` to follow every 1.x release. Save this as `gitrepository-fleet.yaml`:

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
```

Apply it:

```sh
kubectl apply -f gitrepository-fleet.yaml
```

Then check the result:

```sh
flux reconcile kustomization podinfo --with-source
flux get sources git
kubectl -n podinfo get deployment podinfo
```

The revision of `fleet` now starts with `v1.1.0@sha1:`. The repository has the tags `v1.0.0` and `v1.1.0`, and `v1.1.0` is the highest that matches. The Deployment drops to 2 replicas, the value in that release. The change on `main` that asks for 3 replicas is still in Git, but it is not released, so the cluster no longer runs it.

The upper bound `<2.0.0` matters. With an open range such as `>=1.0.0`, a tag `v2.0.0` would reach the cluster the moment someone pushes it, breaking change or not. A range with an upper bound follows patches and minor releases of one major version and waits for a person to move to the next.

## A new release arrives on its own

Now release a new version the way a team would: tag a commit and push the tag. In your clone of `gitops/fleet` (create it with `git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git` if you have none), tag the head of `main`:

```sh
git pull
git tag v1.2.0
git push origin v1.2.0
```

source-controller finds the new tag at its next interval, within a minute. Ask for it now instead of waiting:

```sh
flux reconcile kustomization podinfo --with-source
kubectl -n podinfo get deployment podinfo
```

The revision becomes `v1.2.0@sha1:` and the commit of `main`, and the Deployment goes to 3 replicas. You changed nothing in the cluster: the tag in Git was the release. That is the point of a semver range: releasing is a Git operation, and the range decides which releases the cluster accepts.

You can now pick the commit a `GitRepository` fetches, read the revision that proves it, and follow one release line. The open question is what ends up inside the artifact of that commit, because source-controller does not pack every file.

## Common pitfalls

> [!WARNING]
> - **Leaving out `ref`.** Without it, source-controller follows `master`. On a repository with only `main`, the source never becomes ready.
> - **Setting two fields and expecting the first.** A `tag` next to a `semver` range is ignored, because `semver` wins. Remove the field you do not use.
> - **An open semver range.** `>=1.0.0` accepts `v2.0.0` as soon as it is tagged. Give every range an upper bound.
> - **Pinning a `commit` to "fix" a range.** A commit stops all future releases. It hides the problem instead of fixing the range.
