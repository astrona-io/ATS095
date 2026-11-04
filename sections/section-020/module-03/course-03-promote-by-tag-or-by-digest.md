# Promote By Tag Or By Digest

A release that passed testing in staging should reach production without being rebuilt. Promotion is the act of making the same content available under another name. There are two ways: add a tag, or hand the digest to the next stage. This part compares them, promotes in the playground and then pins a cluster to a digest.

## Promote with a tag

`flux tag artifact` adds a tag to a release that already exists in the registry. No content is uploaded, so the new tag points at the same digest:

```sh
flux tag artifact oci://registry.localtest.me:5001/podinfo-manifests:1.2.0 --tag stable
```

The command has no `--insecure-registry` flag, so it works against registries with HTTPS and not against this playground's plain HTTP registry. The registry API does the same thing on any registry: fetch the manifest of the release and upload it unchanged under the new tag.

<!-- astrona:playground:renew -->

```sh
REG=http://registry.localtest.me:5001/v2/podinfo-manifests
MT='application/vnd.oci.image.manifest.v1+json'
curl -fsS -H "Accept: $MT" $REG/manifests/1.1.0 -o /tmp/manifest.json
curl -fsS -X PUT -H "Content-Type: $MT" --data-binary @/tmp/manifest.json $REG/manifests/stable
flux list artifacts oci://registry.localtest.me:5001/podinfo-manifests --insecure-registry
```

The list now shows `stable` with the same digest as `1.1.0`. Nothing was copied: two tags point at one manifest. A stage that follows `stable` gets the new release at the next interval after you move the tag.

## Promote with a digest

A tag can be moved. If two people promote at the same time, or someone pushes over `stable`, the cluster changes without anyone changing a cluster file. A digest cannot move. When the production `OCIRepository` names a digest, a promotion is a commit that changes that field:

```yaml
spec:
  url: oci://registry.registry.svc.cluster.local:5001/podinfo-manifests
  ref:
    digest: sha256:<digest of the tested release>
```

The change goes through review, it is in Git history, and a rollback is a revert. The cost is one more step in the pipeline: after a release passes in staging, the pipeline writes the digest into the production manifests.

| | Tag promotion | Digest promotion |
| --- | --- | --- |
| Moves automatically | Yes, at the next interval | No, needs a commit |
| Content can change under the name | Yes | No |
| Audit trail | Registry logs, if any | Git history |
| Fits | Staging, fast feedback | Production, change control |

`ref.digest` wins over `tag` and `semver` in the same `ref`, so pinning also protects you if a tag is left behind in the manifest. Remove it anyway, to make the intent clear.

## Find the digest in the cluster

The revision of an `OCIRepository` is `<tag>@sha256:<digest>`. Read it from the cluster to promote exactly what is running:

```sh
kubectl -n flux-system get ocirepository podinfo -o jsonpath='{.status.artifact.revision}{"\n"}'
```

Take the part after `@` and write it into the next stage. This closes the loop: what you tested is what you ship.

## Lab: release and pin

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-095-playground-020-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-020/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-095-lab-020-03
astrona start ats-095-playground-020-03
```
