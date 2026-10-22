# Section 020: OCIRepository And Flux OCI Artifacts

Git is not the only place Flux can read Kubernetes manifests from. A container registry, the same server that stores your images, can also store a folder of manifests as an OCI artifact. The release then becomes an immutable object with a digest, a tag and annotations that say which Git commit it came from. Clusters pull it with the same registry access they already have for images, and they do not need access to the Git server at all.

This section packs manifests into OCI artifacts with `flux push artifact`, lists them, and lets an `OCIRepository` follow a fixed tag, a semver range or a digest. A Flux `Kustomization` then applies whatever the `OCIRepository` fetched.

**Topic covered:** OCI sources

## What you will learn

- What a Flux OCI artifact holds: one compressed layer of manifests, with the Git source and revision as annotations.
- Pushing a folder with `flux push artifact` and listing releases with `flux list artifacts`.
- The fields of an `OCIRepository`: the `oci://` address, `ref` with `tag`, `semver` and `digest`, `insecure`, and the revision `<tag>@sha256:<digest>`.
- How a semver range picks a release, and why a pre-release such as `1.2.0-rc.1` is skipped.
- Connecting a Flux `Kustomization` to an `OCIRepository`.
- What `layerSelector` and signature verification with `verify` are for.

## The learning path

The module has a landing page, two parts, a graded lab right after the part it tests, and a summary. The landing page also starts the module's playground.

### 1. Deliver Manifests As OCI Artifacts

The playground holds Gitea with the repository `gitops/fleet`, and an OCI registry with two releases of the podinfo manifests: `1.0.0` asks for 1 replica and `1.1.0` for 3.

1. Packing Manifests Into An OCI Artifact
2. OCIRepository: Tags, Semver Ranges And Digests, followed by the lab **Follow The Newest 1.x Release From A Registry**
3. Summary

## Section capstone: Repair An OCI Delivery

The capstone is one graded scenario with several independent faults. An `OCIRepository` and a Flux `Kustomization` were written in a hurry: the source cannot fetch anything, and the Flux `Kustomization` points at the wrong kind of source. You fix both in place until the cluster runs the newest 1.x release. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-095-capstone-020
```
