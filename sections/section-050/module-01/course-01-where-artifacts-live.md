# Where Artifacts Live

source-controller is an ordinary Deployment. It fetches a source, builds a `tar.gz` and writes it to a folder inside its container. A small HTTP server in the same process serves that folder. Three settings describe the whole arrangement.

## The storage folder

Read the arguments of the Deployment:

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system get deployment source-controller \
  -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}'
kubectl -n flux-system get deployment source-controller \
  -o jsonpath='{.spec.template.spec.volumes}{"\n"}'
```

You see `--storage-path=/data` and a volume named `data` of the type `emptyDir`. The flag says where artifacts are written. An `emptyDir` lives as long as the pod: it survives a container restart, and it is gone when the pod is replaced. Nothing in the standard installation keeps artifacts across pods, and nothing needs to: source-controller can build them again from the source.

## The address other controllers use

Two more settings make the file reachable:

- `--storage-adv-addr` is the address source-controller **advertises** in the artifact URL. The standard value is a DNS name of the Service `source-controller`.
- The Service `source-controller` in `flux-system` listens on port `80` and forwards to the container port of the artifact server.

```sh
kubectl -n flux-system get service source-controller
kubectl get gitrepositories -A -o custom-columns=NAME:.metadata.name,URL:.status.artifact.url
```

## Anatomy of an artifact URL

The URL has this shape:

```text
http://source-controller.flux-system.svc.cluster.local./gitrepository/flux-system/fleet/<hash>.tar.gz
```

| Part | Meaning |
| --- | --- |
| `source-controller.flux-system.svc.cluster.local.` | The Service, as advertised by `--storage-adv-addr` |
| `gitrepository` | The kind of the source, in lower case |
| `flux-system/fleet` | The namespace and the name of the source |
| `<hash>.tar.gz` | A file named after the revision. The same content under a new commit gives a new file |

Every source kind has its own folder under the same root: `gitrepository`, `ocirepository`, `helmchart`, `helmrepository` and `bucket`. A `HelmRepository` stores its `index.yaml` as an artifact in the same way, and a `HelmChart` stores the packaged chart.

## Common pitfalls

- Expecting artifacts to survive a pod restart. They live in an `emptyDir`.
- Opening the URL from your laptop. The name resolves only inside the cluster, and the network policies block most pods.
- Reading `status.artifact.url` as a Git address. It is the address of the stored file.
