# Overview: Authenticate To Registries And Verify OCI Artifacts (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Flux, a Git server and an OCI registry, pushes two releases, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH and the Flux controllers in `flux-system`. No Flux object reads the registry yet.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). Its folder `apps/podinfo` asks for 2 replicas.
- **An OCI registry** at `registry.localtest.me:5001`, plain HTTP, and **it requires a sign-in**: user `flux`, password `registry-password`. It holds two releases:

  | Release | podinfo replicas |
  | --- | --- |
  | `podinfo-manifests:1.0.0` | 1 |
  | `podinfo-manifests:1.1.0` | 3 |

Start the port-forwards in a second terminal before you use `git`, `flux push artifact`, `flux list artifacts` or `curl` against these services, and leave them running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 &
kubectl -n registry port-forward svc/registry 5001:5001
```

The names `gitea.localtest.me` and `registry.localtest.me` point at `127.0.0.1`. If your router blocks that, add `127.0.0.1 gitea.localtest.me registry.localtest.me` to `/etc/hosts`.

## Helpers

Paste these once in each new terminal. `list_releases` lists the releases in the registry. `podinfo_replicas` prints how many replicas the cluster runs, which tells you which release it applied.

```sh
list_releases() {
  flux list artifacts oci://registry.localtest.me:5001/podinfo-manifests --insecure-registry --creds=flux:registry-password
}
podinfo_replicas() {
  kubectl -n podinfo get deployment podinfo -o jsonpath='{.spec.replicas}{"\n"}'
}
```

Use them like this: `list_releases`, `podinfo_replicas`.

## Practice tasks

- Read the challenge with `curl -si http://registry.localtest.me:5001/v2/` and find the header `WWW-Authenticate`.

- Push `apps/podinfo` from a clone of `gitops/fleet` as `1.2.0-rc.1`, then check that the range `>=1.0.0 <2.0.0` ignores it. Change the range to `>=1.2.0-0 <2.0.0` and watch it take the pre-release.
- Push the same folder twice under two tags and compare the digests with `list_releases`.
- Set `ref.tag` and `ref.semver` together on the `OCIRepository` and predict the revision before you run `flux get sources oci`.
- Remove `insecure: true` and read the error with `flux events --for OCIRepository/podinfo`, then put it back.
- Push a release with `replicas: 0` and watch the Flux `Kustomization` apply it within the interval.
