# Work With Flux Artifacts From The Command Line

The `OCIRepository` is the part of a delivery that runs in the cluster. The other half runs on a laptop or in a pipeline: building the artifact, pushing it, checking it, and moving it from one stage to the next. The `flux` command line has a family of `artifact` commands for exactly this, and they talk to the registry directly. No cluster is needed for most of them.

Keep one sentence in mind: **build once, then promote the same digest.** A release that is rebuilt for every stage is a different release each time. A release that is promoted keeps the digest that you tested.

The module has four parts. **Build And Push A Release With Annotations** packs a folder, pushes it with the source and the revision, and reads the digest. **Pull, Diff And List Releases** fetches a release back, compares it with a folder and filters tags. **Promote By Tag Or By Digest** moves a tested release to the next stage and pins a cluster to the digest, followed by a graded lab. **Sign And Automate In A Pipeline** adds a signature to the push and reads a complete pipeline.

## Learning objectives

After this module you can:

- Push a folder with `flux push artifact` and set `--source`, `--revision`, `--annotations` and `--output json`.
- Build an artifact file locally with `flux build artifact`, and say what the default ignore paths remove.
- Pull a release with `flux pull artifact`, compare it with `flux diff artifact`, and filter tags with `flux list artifacts`.
- Promote a release by adding a tag, and say why a promotion by digest is safer.
- Pin an `OCIRepository` to the digest of a release.
- Sign a pushed release with cosign using the digest from `--output json`.

## Before you start

You need the `OCIRepository` and `flux push artifact` from the first module of this section.

Your playground is a single-node `kind` cluster with **Flux v2.9.6**, Gitea and an OCI registry.

| Service | Details |
| --- | --- |
| Gitea | Git server with the repository `gitops/fleet` (user `gitops`, password `gitops-password`) |
| OCI registry | `registry.localtest.me:5001`, plain HTTP, no sign-in. Holds `podinfo-manifests:1.0.0` (1 replica) and `podinfo-manifests:1.1.0` (3 replicas) |

On your machine the registry answers while a port-forward runs, so open a second terminal and leave this running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 &
kubectl -n registry port-forward svc/registry 5001:5001
```

If your router blocks the names, add `127.0.0.1 gitea.localtest.me registry.localtest.me` to `/etc/hosts`. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
