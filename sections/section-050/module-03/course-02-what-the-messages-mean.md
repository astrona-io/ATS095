# What The Messages Mean

The exact wording changes between versions, so match on the **kind** of the message, not on every word.

## Git

| The message is about | Likely cause | Fix |
| --- | --- | --- |
| authentication required or failed | Wrong or missing `username`/`password` in the Secret; wrong deploy key | Recreate the Secret with the same name; check the user can read the repository |
| a reference that was not found | `ref.branch`, `ref.tag` or `ref.commit` that does not exist | Patch `spec.ref` |
| the repository not found | A typo in `spec.url`, or the user cannot see a private repository | Check the URL and the permissions |
| a host key or `known_hosts` problem | SSH only: the host key in the Secret does not match the server | See section 010 |
| a timeout or a connection refused | Network, DNS or a proxy | Test the name from a pod; check `spec.proxySecretRef` |

## OCI

| The message is about | Likely cause | Fix |
| --- | --- | --- |
| 401 or unauthorized | No credentials, or wrong ones | `spec.secretRef` or `serviceAccountName` or `provider` |
| the tag or manifest not found | The tag was never pushed, or the semver range matches nothing | `flux list artifacts` against the repository |
| an unknown certificate authority | A private CA | `certSecretRef` with `ca.crt` |
| HTTP versus HTTPS | A registry without TLS | `insecure: true` |

## Helm

| The message is about | Likely cause | Fix |
| --- | --- | --- |
| the chart not found in the index | A wrong `chart` name or a version range with no match | `helm search repo` or read `index.yaml` |
| the index cannot be loaded | A wrong `url`, an access problem, or an index that is very large | Open the URL from a pod; raise memory |
| a registry login problem for OCI charts | Missing `type: oci` or credentials | Set `type: oci` and `secretRef` |

## Bucket

| The message is about | Likely cause | Fix |
| --- | --- | --- |
| access denied or an invalid key | Wrong `accesskey`/`secretkey` keys in the Secret | Fix the key names and values |
| the bucket does not exist | A wrong `bucketName` or `endpoint` | Check both |
| a TLS or an HTTP problem | `insecure` does not match the endpoint | Set it to the scheme of the endpoint |

<!-- astrona:playground:renew -->

Try three of these in the playground: create a `GitRepository` with `ref.branch: nope`, another with a wrong password in its Secret, and another with a URL that points at a repository that does not exist. Read all three with `flux get sources git` and compare the messages.

```sh
flux create secret git bad-auth --url=http://gitea.localtest.me:3000/gitops/fleet.git --username=gitops --password=wrong
flux create source git bad-auth --url=http://gitea.localtest.me:3000/gitops/fleet.git --branch=main --secret-ref=bad-auth
flux create source git bad-ref --url=http://gitea.localtest.me:3000/gitops/fleet.git --branch=nope --secret-ref=fleet-auth
flux get sources git
```

## Common pitfalls

- Treating a "not found" as a network problem. A private repository that the user cannot see often answers "not found".
- Changing the interval to "retry faster". A failing source retries with back-off; use `flux reconcile`.
- Fixing the Secret and not the reference (or the reverse). Check the whole list.
