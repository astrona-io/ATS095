# Packing Manifests Into An OCI Artifact

A Git commit is a good record of a change, but a poor unit of release: it holds the whole repository, it can be rewritten, and every cluster that reads it needs access to the Git server. An OCI artifact turns one folder of one commit into a release that lives in a container registry. This part pushes such a release with `flux push artifact` and then reads back exactly what the registry stored.

## Push a release from Git

A release starts in Git. Clone `gitops/fleet` with the port-forwards running, and keep the commit you are about to release in a variable:

<!-- astrona:playground:renew -->

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
COMMIT="$(git rev-parse HEAD)"
```

`flux push artifact` packs a folder into an OCI artifact and pushes it to a registry under a tag. It also records where the content came from: `--source` takes the Git URL, and `--revision` takes the branch or tag and the commit, in the form `main@sha1:<commit>`. The registry in this playground uses plain HTTP, so the command needs `--insecure-registry`; a real registry uses HTTPS and does not. Push the folder `apps/podinfo` as release `1.2.0`:

```sh
flux push artifact oci://registry.localtest.me:5001/podinfo-manifests:1.2.0 \
  --path=./apps/podinfo \
  --source="http://gitea.localtest.me:3000/gitops/fleet.git" \
  --revision="main@sha1:$COMMIT" \
  --insecure-registry
```

The command reports that it pushed the artifact and prints its address with the digest. The **digest** is the `sha256` hash of the artifact's manifest, the small JSON document that describes it. The same content always gives the same digest, so a digest names one exact release.

## List the releases

The registry now holds three tags of `podinfo-manifests`. `flux list artifacts` asks the registry for the tags of one repository and prints them with their digest and the source and revision annotations:

```sh
flux list artifacts oci://registry.localtest.me:5001/podinfo-manifests --insecure-registry
```

The list shows `1.0.0`, `1.1.0` and `1.2.0`. The first two came from the playground's setup, and `1.2.0` carries your commit as its revision. That annotation is what links a release in the registry back to the exact commit in Git.

## Read what the registry stored

A registry is an HTTP API, so you can read the manifest of a release directly. The `Accept` header asks for the OCI manifest format:

```sh
curl -s -H 'Accept: application/vnd.oci.image.manifest.v1+json' \
  http://registry.localtest.me:5001/v2/podinfo-manifests/manifests/1.2.0 \
  | jq '{config: .config.mediaType, layers: [.layers[].mediaType], annotations}'
```

The manifest has one config and one layer. The config has the media type `application/vnd.cncf.flux.config.v1+json`, and the layer has `application/vnd.cncf.flux.content.v1.tar+gzip`: a compressed archive of the files in `apps/podinfo`. A **media type** is the label that says what kind of content a blob holds, so tools know how to read it. The annotations hold `org.opencontainers.image.source` with your Git URL, `org.opencontainers.image.revision` with `main@sha1:` and your commit, and `org.opencontainers.image.created` with the time.

```mermaid
flowchart TB
    G["Git commit"] -->|"flux push artifact"| M["OCI manifest"]
    M -->|"config"| C["flux.config.v1+json"]
    M -->|"layer"| L["flux.content.v1.tar+gzip"]
    M -->|"annotations"| A["source and revision"]
```

The diagram shows one push: the files of a Git folder become the single layer of an OCI manifest, and the commit becomes its annotations.

## Tags and immutability

A tag is a name that points at a digest, and a registry lets you move it. Push `1.2.0` again after a commit and the tag points at new content, while every cluster that pinned the old digest keeps the old content. That is why teams use a new tag for every release and treat a version tag as fixed.

`flux tag artifact` adds another tag to an existing artifact without pushing it again, for example `latest` or `stable` on top of `1.2.0`. Use it against registries with HTTPS; this playground's registry needs `--insecure-registry`, which `flux tag artifact` does not offer, so it is not part of the hands-on steps here.

You can now push a folder as a release, list the releases with their source and revision, and read the manifest the registry stored. The open question is how a cluster picks one of these releases, which is the job of the `OCIRepository`.

## Common pitfalls

> [!WARNING]
> - **Pushing without `--source` and `--revision`.** The release then carries no link back to Git, and nobody can tell which commit it holds.
> - **Putting the tag in the wrong place.** The tag belongs at the end of the `oci://` address in `flux push artifact`. In an `OCIRepository`, the address has no tag.
> - **Reusing a tag for new content.** It works, but clusters that follow the tag get different content under the same name. Use a new version for every release.
> - **Forgetting the port-forward.** `flux push artifact` runs on your machine and needs `registry.localtest.me:5001` to answer there.
