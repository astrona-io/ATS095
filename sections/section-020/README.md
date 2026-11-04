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

Each module has a landing page, several parts, graded labs right after the parts they test, and a summary. The landing page also starts the module's playground.

### 1. Deliver Manifests As OCI Artifacts

The playground holds Gitea with the repository `gitops/fleet`, and an OCI registry with two releases of the podinfo manifests: `1.0.0` asks for 1 replica and `1.1.0` for 3.

1. Packing Manifests Into An OCI Artifact
2. OCIRepository: Tags, Semver Ranges And Digests, followed by the lab **Follow The Newest 1.x Release From A Registry**
3. OCIRepository Status, Conditions And Troubleshooting, followed by the lab **Repair An OCIRepository That Does Not Fetch**
4. Layers, semverFilter And Ignore Rules
5. Summary

What you will also learn in this module:

- The conditions `Ready`, `FetchFailed` and `ArtifactInStorage`, the artifact metadata, and how to fix a source from its events.
- How `semverFilter`, `layerSelector` and `ignore` shape the tags, the layer and the files a source takes.

### 2. Authenticate To Registries And Verify OCI Artifacts

The playground holds a registry that requires a sign-in (user `flux`, password `registry-password`).

1. Registry Credentials With A Pull Secret, followed by the lab **Sign In To A Private Registry Lab**
2. ServiceAccount And Cloud Identity
3. TLS Certificates And Proxies
4. Verify Signatures With cosign
5. Summary

What you will learn in this module: `flux create secret oci`, `secretRef`, `serviceAccountName` and `provider` for `aws`, `azure` and `gcp`, `certSecretRef` and `proxySecretRef`, and `spec.verify` with cosign, keyless identities and notation.

### 3. Work With Flux Artifacts From The Command Line

The playground holds Gitea and an unauthenticated registry with `podinfo-manifests:1.0.0` and `1.1.0`.

1. Build And Push A Release With Annotations
2. Pull, Diff And List Releases
3. Promote By Tag Or By Digest, followed by the lab **Release And Pin An Artifact With The Flux CLI**
4. Sign And Automate In A Pipeline
5. Summary

What you will learn in this module: `flux build`, `push`, `pull`, `diff`, `list` and `tag artifact`, annotations and digests, promotion by tag or by digest, and signing the pushed digest.

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
