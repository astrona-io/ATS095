# Verify Commits, Include Repositories And Fetch Less

A `GitRepository` fetches a whole repository by default and trusts whatever the branch points at. Real repositories are larger than the part a cluster needs, they depend on other repositories, and a commit on a branch can come from anyone with push access. Flux has a field for each of these problems: `spec.verify`, `spec.recurseSubmodules`, `spec.include`, `spec.sparseCheckout` and `spec.ref.name`.

A **`GitRepository`** is the Flux object that tells source-controller which Git repository to fetch. **source-controller** is the Flux controller that fetches sources and stores each revision as an artifact, a compressed archive of the files. A **Git reference** is a name that points at a commit: a branch, a tag or another ref.

Keep one sentence in mind: **the artifact holds exactly what the `GitRepository` spec says to fetch, so a wrong field shows up as a missing file or a failed condition.**

The module has four parts. **Verify Commit And Tag Signatures** explains `spec.verify` and the `SourceVerifiedCondition`. **Submodules And Included Repositories** compares `recurseSubmodules` with `include`. **Sparse Checkout And Smaller Artifacts** fetches only some directories. **Exact Git References With ref.name** covers full reference names and which `ref` field wins. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Say what the four `verify` modes check and which keys a verification Secret needs.
- Read the `SourceVerifiedCondition` on a `GitRepository`.
- Explain when to use `recurseSubmodules` and when to use `include`.
- Limit an artifact to chosen directories with `sparseCheckout`.
- Fetch a pull request or a tag with `ref.name`, and tell which `ref` field wins.

## Before you start

You need the basics of a `GitRepository`, a Secret and a Flux `Kustomization` (the Flux object that applies manifests from a source).

Your playground is a single-node `kind` cluster with **Flux v2.9.6** and Gitea, an in-cluster Git server, with the lab-only user `gitops` and the password `gitops-password`.

| What | Details |
| --- | --- |
| `gitops/fleet` | Private repository with `apps/podinfo`, `clusters/kind`, `docs`, tags `v1.0.0` and `v1.1.0`, and `main` |
| `gitops/platform` | Private repository with `podinfo-settings/configmap.yaml` |
| `GitRepository` `fleet` | Follows `main` of `gitops/fleet` over HTTP with the Secret `fleet-auth` |
| Flux `Kustomization` `podinfo` | Applies `./apps/podinfo` from `fleet` |

On your machine the Git server answers while a port-forward runs, so open a second terminal and leave this running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

If your router blocks the name `gitea.localtest.me`, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
