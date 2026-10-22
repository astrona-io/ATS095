# Overview: Control What source-controller Fetches From Git (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Flux and a Git server, connects Flux to a repository, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH and the Flux controllers in the namespace `flux-system`. source-controller is the controller that fetches sources and stores each revision as an artifact.
- **Gitea**, an in-cluster Git server in the namespace `gitea`, with the lab-only user `gitops` and the password `gitops-password`. It answers HTTP on port `3000` and SSH on port `2222`.

  | Repository | What it holds |
  | --- | --- |
  | `gitops/fleet` | `apps/podinfo`, `clusters/kind`, and a `docs` folder with a Markdown file and a `.png` file. Tag `v1.0.0` asks for 1 podinfo replica, tag `v1.1.0` for 2, and `main` for 3 |
  | `gitops/platform` | `podinfo-settings/configmap.yaml` |

- The `GitRepository` `fleet` follows `main` of `gitops/fleet` over HTTP with the Secret `fleet-auth`, and the Flux `Kustomization` `podinfo` applies `./apps/podinfo` from it.

Start the port-forward in a second terminal before you use `git`, `curl` or `flux create secret git` against Gitea, and leave it running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

The name `gitea.localtest.me` points at `127.0.0.1`. If your router blocks that, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

## Helpers

Paste these once in each new terminal. `list_artifact_files` prints the files in the artifact of one `GitRepository`, using a short-lived pod in `flux-system` because the Flux network policies block other namespaces. `podinfo_replicas` prints how many replicas the cluster runs, which tells you which release it applied.

```sh
list_artifact_files() {
  ARTIFACT_URL="$(kubectl -n flux-system get gitrepository "$1" -o jsonpath='{.status.artifact.url}')"
  kubectl -n flux-system run artifact-reader --rm -i --restart=Never --quiet \
    --image=nicolaka/netshoot:v0.13 -- sh -c "curl -s '$ARTIFACT_URL' | tar -tzf -"
}
podinfo_replicas() {
  kubectl -n podinfo get deployment podinfo -o jsonpath='{.spec.replicas}{"\n"}'
}
```

Use them like this: `list_artifact_files fleet`, `podinfo_replicas`.

## Practice tasks

- Set both `tag: v1.0.0` and `semver: ">=1.0.0 <2.0.0"` on `fleet`. Predict the revision before you run `flux get sources git`, then remove the field you do not need.
- Clone `gitops/fleet` with `git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git`, push a tag `v2.0.0`, and confirm the range `>=1.0.0 <2.0.0` ignores it.
- Commit a `.sourceignore` with the line `docs/` to `main`. Compare the artifact of a `GitRepository` that follows `main` with one that follows a release tag.
- Set `ref.commit` to the commit of `v1.0.0` (find it in the revision) and watch `podinfo_replicas` drop to 1.
- Create `platform-ssh` with `flux create secret git`, list its keys with `kubectl -n flux-system get secret platform-ssh -o jsonpath='{.data}' | jq 'keys'`, and move the `GitRepository` `platform` to SSH.
