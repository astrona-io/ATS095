# Build And Push A Release With Annotations

`flux push artifact` does three things in one command: it packs a folder into a compressed archive, uploads it to a registry and tags it. This part looks at what goes into the archive, how to add your own annotations, and how to get the digest back in a form a script can use.

## What goes into the archive

The command packs the folder you give with `--path`. It skips some files by default: `.git/`, `.gitignore`, `.gitmodules`, `.gitattributes`, and images and archives (`*.jpg`, `*.jpeg`, `*.gif`, `*.png`, `*.wmv`, `*.flv`, `*.tar.gz`, `*.zip`). `--ignore-paths` replaces that list and `--add-ignore-paths` adds to it, both in `.gitignore` format.

To see the result without a registry, `flux build artifact` writes the same archive to a local file. Run it in the playground and list what is inside:

<!-- astrona:playground:renew -->

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
flux build artifact --path=./apps/podinfo --output=/tmp/podinfo.tgz
tar -tzf /tmp/podinfo.tgz
```

The listing shows the manifests of `apps/podinfo` and nothing from `.git`. Build is the safe step: it changes nothing outside your machine, so you can run it in a pull request to check what would be released.

## Push with the source and the revision

The push adds two annotations that link the release to Git. `--source` is the Git URL and `--revision` is `<branch or tag>@sha1:<commit>`. Add your own with `--annotations`, which you can repeat:

```sh
COMMIT="$(git rev-parse HEAD)"
flux push artifact oci://registry.localtest.me:5001/podinfo-manifests:1.2.0 \
  --path=./apps/podinfo \
  --source="http://gitea.localtest.me:3000/gitops/fleet.git" \
  --revision="main@sha1:$COMMIT" \
  --annotations='org.opencontainers.image.description=podinfo manifests for staging' \
  --insecure-registry
```

The extra annotation is stored in the manifest next to the source and the revision. Source-controller copies the annotations into `status.artifact.metadata` of every `OCIRepository` that fetches the release, so the cluster itself can tell you where its content came from.

## Get the digest in a script

A pipeline needs the digest of what it just pushed, to sign it or to pin to it. With `--output json` the command prints a JSON document instead of text:

```sh
flux push artifact oci://registry.localtest.me:5001/podinfo-manifests:1.2.0 \
  --path=./apps/podinfo \
  --source="http://gitea.localtest.me:3000/gitops/fleet.git" \
  --revision="main@sha1:$COMMIT" \
  --insecure-registry \
  --output json | jq -r '.repository + "@" + .digest'
```

The result is an address of the form `registry.localtest.me:5001/podinfo-manifests@sha256:<digest>`. Pushing the same folder again gives the same digest, because the archive is built so that equal content gives an equal result. A digest is therefore a fingerprint of the content, and a new push of unchanged content moves nothing.

## Ask the registry directly

The CLI is a convenience over the registry API, and the API is always available. The digest of a tag is in the header `Docker-Content-Digest` of a request for its manifest:

```sh
curl -fsSI -H 'Accept: application/vnd.oci.image.manifest.v1+json' \
  http://registry.localtest.me:5001/v2/podinfo-manifests/manifests/1.2.0 \
  | grep -i docker-content-digest
```

Use this when the CLI is not installed, for example in a slim CI image.

## Common pitfalls

> [!WARNING]
> - **Packing the wrong folder.** `--path` is relative to where you run the command. Build first and list the archive.
> - **Expecting images in the archive.** The default ignore list removes `*.png`, `*.zip` and similar files. Use `--ignore-paths` to change it.
> - **Pushing from a dirty checkout.** The revision names the commit, but the archive holds the files on disk, including uncommitted changes. Push from a clean checkout in CI.
> - **Using `latest`.** A moving tag hides which release a cluster runs. Push a version and let a promotion move other tags.
