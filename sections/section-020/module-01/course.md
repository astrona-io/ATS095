# Deliver Manifests As OCI Artifacts

In a Git-based setup, every cluster needs credentials for the Git server and fetches the whole repository to find one folder. Many teams already run a container registry that every cluster can reach. They push their manifests there as a release, next to the images, and let the clusters pull that release.

An **OCI artifact** is content stored in a container registry the same way as an image. OCI is the Open Container Initiative, the group that defines the image and registry formats. A Flux OCI artifact holds a folder of Kubernetes manifests as one compressed layer, and the registry gives it a tag and a digest like any image. An **`OCIRepository`** is the Flux object that tells source-controller which OCI artifact to fetch.

Keep one sentence in mind: **a tag can move, a digest cannot.** The revision Flux reports for an OCI source holds both, so you always know which exact content the cluster runs.

The module has four parts. **Packing Manifests Into An OCI Artifact** pushes a folder from Git to the registry with `flux push artifact` and reads back what was stored. **OCIRepository: Tags, Semver Ranges And Digests** points an `OCIRepository` at those releases, compares the three ways to pick one, and connects a Flux `Kustomization`. **OCIRepository Status, Conditions And Troubleshooting** reads the conditions and events and fixes a source that does not fetch, followed by a graded lab. **Layers, semverFilter And Ignore Rules** shapes which tags and which content a source takes. Graded labs follow the second and the third part.

## Learning objectives

After this module you can:

- Explain what a Flux OCI artifact holds and which annotations `flux push artifact` adds.
- Push a folder of manifests to a registry with `flux push artifact`, and list the releases with `flux list artifacts`.
- Write an `OCIRepository` that follows a tag, a semver range or a digest, and say which one wins.
- Read a revision such as `1.1.0@sha256:<digest>`.
- Allow a registry that uses plain HTTP with `insecure: true`, and say why a real registry should not need it.
- Connect a Flux `Kustomization` to an `OCIRepository` and prove which release it applied.
- Read the conditions, events and artifact metadata of an `OCIRepository` and fix a source that does not fetch.
- Filter tags with `semverFilter` and select a layer with `layerSelector`.

## Before you start

You need Kubernetes basics and Git from the terminal, and you should know that a Flux `Kustomization` is the Flux object that applies one folder of a source's artifact to the cluster. Knowing what a container image tag is helps.

Your playground is a single-node `kind` cluster with **Flux v2.9.6** and the `flux` command-line tool, and two in-cluster services:

| Service | Details |
| --- | --- |
| Gitea | Git server with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). Its `apps/podinfo` folder asks for 2 replicas |
| OCI registry | `registry.localtest.me:5001`, plain HTTP. Holds `podinfo-manifests:1.0.0` (1 replica) and `podinfo-manifests:1.1.0` (3 replicas) |

No Flux object reads the registry yet. Both services answer under the same names inside the cluster and on your machine, but on your machine only while port-forwards run. Open a second terminal now and leave this running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 &
kubectl -n registry port-forward svc/registry 5001:5001
```

The names `gitea.localtest.me` and `registry.localtest.me` point at `127.0.0.1`. If your router blocks that, add `127.0.0.1 gitea.localtest.me registry.localtest.me` to `/etc/hosts`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
