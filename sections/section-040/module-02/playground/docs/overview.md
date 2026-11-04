# Overview: Receivers And Source Notifications (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Flux and an S3-compatible server, fills a bucket, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH and the Flux controllers in `flux-system`. No Flux object reads the bucket yet.
- In the namespace **`s3`**:

  | Name | What it is |
  | --- | --- |
  | `versitygw` (Service `s3`) | An S3-compatible server at `s3.s3.svc.cluster.local:9000`, plain HTTP. Lab-only access key `flux-s3`, secret key `flux-s3-secret` |
  | bucket `podinfo` | `namespace.yaml`, `deployment.yaml` (2 replicas), `service.yaml` and the Kustomize file `kustomization.yaml` |
  | `s3-client` | A pod with the `aws` command-line tool, already set up for this server |
  | `sink` (Service `sink`, port `8080`) | A tiny HTTP server that prints every POST it receives; read it with `kubectl -n s3 logs deploy/sink` |

## Helpers

Paste these once in each new terminal. `s3` runs one `aws s3` command in the client pod; add `-i` input with `<` to upload a local file. `request_reconcile` sets a new `reconcile.fluxcd.io/requestedAt` on one source.

```sh
s3() {
  kubectl -n s3 exec -i deploy/s3-client -- aws s3 "$@"
}
request_reconcile() {
  kubectl -n flux-system annotate --overwrite "$1" reconcile.fluxcd.io/requestedAt="$(date +%s)"
}
```

Use them like this: `s3 ls s3://podinfo`, `s3 cp - s3://podinfo/deployment.yaml < deployment.yaml`, `request_reconcile bucket/podinfo`.

## Practice tasks

- Create a `Bucket` with the Secret keys named `access_key` and `secret_key`, and read the error with `flux events --for Bucket/<name>`.
- Upload a file that the default ignore rules exclude, such as `notes.png`, and check whether the revision changes.
- Set `prefix` on a `Bucket` to read only part of a bucket, after uploading files under a folder.
- Run `request_reconcile bucket/podinfo` twice in the same second, and explain why the second one may do nothing.
- Delete the source-controller pod with `kubectl -n flux-system delete pod -l app=source-controller` and watch the artifact `lastUpdateTime` after it comes back.
