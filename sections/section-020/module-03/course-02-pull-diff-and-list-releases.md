# Pull, Diff And List Releases

Once releases are in a registry, you need to look at them without a cluster: fetch one to read its files, compare the registry with your working copy, and find the newest version. This part uses `flux pull artifact`, `flux diff artifact` and `flux list artifacts`.

## Pull a release

`flux pull artifact` downloads a release and extracts it into a folder. Pull `1.1.0`:

<!-- astrona:playground:renew -->

```sh
flux pull artifact oci://registry.localtest.me:5001/podinfo-manifests:1.1.0 \
  --output=/tmp/podinfo-1.1.0 --insecure-registry
ls /tmp/podinfo-1.1.0
grep replicas /tmp/podinfo-1.1.0/*.yaml
```

The folder holds the manifests that were pushed, and the Deployment asks for 3 replicas. This is how you inspect what a cluster really runs: the digest in the revision of an `OCIRepository` names exactly this content. Pull by digest to be sure. The address takes `@sha256:<digest>` in place of the tag:

```sh
DIGEST="$(curl -fsSI -H 'Accept: application/vnd.oci.image.manifest.v1+json' \
  http://registry.localtest.me:5001/v2/podinfo-manifests/manifests/1.1.0 \
  | tr -d '\r' | awk 'tolower($1)=="docker-content-digest:" {print $2}')"
flux pull artifact "oci://registry.localtest.me:5001/podinfo-manifests@$DIGEST" \
  --output=/tmp/podinfo-by-digest --insecure-registry
diff -r /tmp/podinfo-1.1.0 /tmp/podinfo-by-digest && echo "same content"
```

## Compare with a folder

`flux diff artifact` compares a release in the registry with a local folder. Clone `gitops/fleet` and compare `1.1.0` with the folder on `main`:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
flux diff artifact oci://registry.localtest.me:5001/podinfo-manifests:1.1.0 \
  --path=./fleet/apps/podinfo --insecure-registry
echo "exit code: $?"
```

The command prints what differs and exits with a non-zero code when the folder and the release are not equal. The folder on `main` asks for 2 replicas and the release asks for 3, so the command reports a difference. In CI, this decides whether a new release is needed at all: when the diff is empty, you do not push.

## List and filter

`flux list artifacts` prints the tags of a repository with their digest and the annotations:

```sh
flux list artifacts oci://registry.localtest.me:5001/podinfo-manifests --insecure-registry
```

Two filters narrow the list. `--filter-semver` takes a semver range, and `--filter-regex` takes a regular expression:

```sh
flux list artifacts oci://registry.localtest.me:5001/podinfo-manifests \
  --filter-semver '>=1.1.0' --insecure-registry
flux list artifacts oci://registry.localtest.me:5001/podinfo-manifests \
  --filter-regex '^1\.0\.' --insecure-registry
```

These are the same ideas as `semver` and `semverFilter` in the `OCIRepository`, so you can test a range on your machine before you put it in a manifest. If the CLI shows the tag you expect and the cluster does not, the problem is in the source object, not in the registry.

## Common pitfalls

> [!WARNING]
> - **Treating a non-zero exit of `diff` as a failure.** It means the content differs. Check the output, and read the exit code as a yes or no.
> - **Pulling into a folder with old files.** The extraction does not remove files that are no longer in the release. Pull into an empty folder.
> - **Comparing the wrong path.** The diff is against the folder you give. Compare with the same path you pushed from.
> - **Forgetting `--insecure-registry`.** On a plain HTTP registry, every command that contacts it needs the flag.
