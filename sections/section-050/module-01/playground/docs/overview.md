# Overview: How source-controller Stores And Serves Artifacts (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Flux and a Git server, connects Flux to a repository, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH and the Flux controllers in the namespace `flux-system`. source-controller is the controller that fetches sources and stores each revision as an artifact.
- **Gitea**, an in-cluster Git server in the namespace `gitea`, with the lab-only user `gitops` and the password `gitops-password`. It answers HTTP on port `3000`.

  | Repository | What it holds |
  | --- | --- |
  | `gitops/fleet` | `apps/podinfo`, `clusters/kind`, and a `docs` folder. Tag `v1.0.0` asks for 1 podinfo replica, tag `v1.1.0` for 2, and `main` for 3 |
  | `gitops/platform` | `podinfo-settings/configmap.yaml` |

- The `GitRepository` `fleet` follows `main` of `gitops/fleet` over HTTP with the Secret `fleet-auth`, and the Flux `Kustomization` `podinfo` applies `./apps/podinfo` from it.

Start the port-forward in a second terminal before you use `git` or `curl` against Gitea, and leave it running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

The name `gitea.localtest.me` points at `127.0.0.1`. If your router blocks that, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

## Helpers

Paste these once in each new terminal. They use a short-lived pod in `flux-system` because the Flux network policies block other namespaces from the artifact server.

```sh
list_artifact_files() {
  ARTIFACT_URL="$(kubectl -n flux-system get gitrepository "$1" -o jsonpath='{.status.artifact.url}')"
  kubectl -n flux-system run artifact-reader --rm -i --restart=Never --quiet \
    --image=nicolaka/netshoot:v0.13 -- sh -c "curl -s '$ARTIFACT_URL' | tar -tzf -"
}
artifact_digest() {
  ARTIFACT_URL="$(kubectl -n flux-system get gitrepository "$1" -o jsonpath='{.status.artifact.url}')"
  kubectl -n flux-system run artifact-reader --rm -i --restart=Never --quiet \
    --image=nicolaka/netshoot:v0.13 -- sh -c "curl -s '$ARTIFACT_URL' | sha256sum"
}
```

Use them like this: `list_artifact_files fleet`, `artifact_digest fleet`.

## Practice tasks

- Run `list_artifact_files fleet` and `artifact_digest fleet`, then compare the digest with `kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.digest}'`.
- Create the sources `platform` (branch `main` of `gitops/platform`, with a Secret made by `flux create secret git`) and list the files of its artifact.
- Print the artifact URLs of all sources with `kubectl get gitrepositories -A -o custom-columns=NAME:.metadata.name,URL:.status.artifact.url`.
- Delete the pod of source-controller (`kubectl -n flux-system delete pod -l app=source-controller`) and watch `flux get sources git` while it fetches again.
- Push a new commit to `gitops/fleet` and watch `status.artifact.revision` and `lastUpdateTime` change.
