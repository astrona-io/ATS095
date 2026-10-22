# Shaping The Artifact With ignore And include

source-controller does not hand the Git commit itself to the other controllers. It packs the files of the commit into an artifact, and on the way it leaves some files out. A repository full of documentation, images and CI files makes every artifact bigger and slower to move, and a file that should not reach the cluster may slip in. This part opens an artifact, shows what the default rules leave out, and then changes the contents in both directions: fewer files with ignore rules, and more files with an include from a second repository.

## Open an artifact

The artifact is a `tar.gz` file that source-controller serves over HTTP inside the cluster. Its address is in the status of the `GitRepository`. `flux install` also creates network policies that only let pods in the namespace `flux-system` talk to source-controller, so you read the artifact with a short-lived pod in that namespace. Paste this helper into your terminal; it prints every file name in the artifact of one `GitRepository`:

<!-- astrona:playground:renew -->

```sh
list_artifact_files() {
  ARTIFACT_URL="$(kubectl -n flux-system get gitrepository "$1" -o jsonpath='{.status.artifact.url}')"
  kubectl -n flux-system run artifact-reader --rm -i --restart=Never --quiet \
    --image=nicolaka/netshoot:v0.13 -- sh -c "curl -s '$ARTIFACT_URL' | tar -tzf -"
}
list_artifact_files fleet
```

The list shows the files under `apps/podinfo`, `clusters/kind/README.md` and `docs/architecture.md`. The commit also holds `docs/diagram.png`, but the artifact does not. source-controller left it out because of its **default ignore rules**, a built-in list in the same format as a `.gitignore` file.

## What the default rules leave out

The default list covers files that never belong in a cluster. It leaves out Git's own files (`.git/`, `.gitignore`, `.gitmodules`, `.gitattributes`), images, videos and archives (`.jpg`, `.jpeg`, `.gif`, `.png`, `.wmv`, `.flv`, `.tar.gz`, `.zip`), the configuration of common CI systems (`.github/`, `.circleci/`, `.travis.yml`, `.gitlab-ci.yml` and a few more), and tool files such as `.goreleaser.yml` and `.sops.yaml`.

Two settings change the list, and they behave differently. A **`.sourceignore` file** in the repository adds rules: source-controller reads it in the root and in any folder, and keeps the defaults. The field **`spec.ignore`** in the `GitRepository` replaces the defaults with its own rules, so you must repeat any default you still want.

There is also a difference in when each one takes effect. A `.sourceignore` file is part of a commit, so it only affects the commits that contain it. `fleet` follows release tags, and the release `v1.2.0` has no `.sourceignore`, so a file you push to `main` today changes nothing until the next release. `spec.ignore` lives in the cluster and applies to the next fetch.

## Leave the docs folder out

The `docs` folder is for people, not for the cluster. Leave it out now with `spec.ignore`. Because `spec.ignore` replaces the defaults, the rules below also repeat the image rule that hid `diagram.png`. Save this as `gitrepository-fleet.yaml`:

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
  ignore: |
    /docs/
    *.png
```

Apply it:

```sh
kubectl apply -f gitrepository-fleet.yaml
```

Then check the result:

```sh
flux reconcile source git fleet
list_artifact_files fleet
```

The `docs` folder is gone from the list, and `apps/podinfo` is still there. The commit is the same as before, so the revision stays the same: the revision names the commit, not the contents of the artifact. A leading `/` anchors a rule to the root of the repository, so `/docs/` only matches the top-level `docs` folder.

## Add files from a second repository

The opposite need is common too. A platform team keeps shared files in its own repository, and an application needs some of them next to its own manifests. `spec.include` copies the artifact of another `GitRepository` into this one. The second repository needs its own `GitRepository` first. The Secret `fleet-auth` holds the `gitops` user's password, which also opens `gitops/platform`. Save this as `gitrepository-platform.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: platform
  namespace: flux-system
spec:
  interval: 5m
  url: http://gitea.localtest.me:3000/gitops/platform.git
  ref:
    branch: main
  secretRef:
    name: fleet-auth
```

Apply it:

```sh
kubectl apply -f gitrepository-platform.yaml
```

Now tell `fleet` to include it. `fromPath` picks one folder of the included artifact, and `toPath` says where it lands in the artifact of `fleet`; without `toPath`, the files land in a folder named after the included `GitRepository`. Run this to add the include to `fleet`:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge -p \
  '{"spec":{"include":[{"repository":{"name":"platform"},"fromPath":"podinfo-settings","toPath":"platform/podinfo-settings"}]}}'
flux reconcile source git fleet
list_artifact_files fleet
```

The list now holds `platform/podinfo-settings/configmap.yaml` next to the files of `gitops/fleet`. source-controller built one artifact from two repositories, so a Flux `Kustomization` that reads `fleet` can reference that file. When `gitops/platform` gets a new commit, source-controller builds a new artifact for `fleet` too.

A related field, `spec.recurseSubmodules`, is for repositories that use Git submodules: when it is `true`, source-controller also clones every submodule. It is `false` by default, and includes are usually the clearer choice, because each included repository is a Flux object you can see with `flux get`.

You now control both what source-controller fetches and what it packs. The open question is how it proves to the Git server that it may read the repository at all, which is what the credentials in `fleet-auth` do.

## Common pitfalls

> [!WARNING]
> - **Adding a `.sourceignore` and expecting an instant change on a tag-based source.** The file only affects commits that contain it. Use `spec.ignore` for an immediate change, or release a new tag.
> - **Forgetting that `spec.ignore` replaces the defaults.** Without the default rules, images and other files you never wanted come back. Repeat the rules you still need.
> - **Reading the artifact from a pod in another namespace.** The Flux network policies block it, and `curl` only times out. Use a short-lived pod in `flux-system`.
> - **Including a repository with no `GitRepository`.** `spec.include` names a Flux object, not a URL. Create the `GitRepository` first.
