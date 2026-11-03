# HTTP Proxies And Timeouts

In many companies the cluster cannot reach the internet or the Git server directly. All outgoing HTTP traffic goes through a proxy server. This part shows how to give one `GitRepository` a proxy, why that is safer than a setting for the whole controller, and how `spec.timeout` limits a slow fetch.

## The proxy Secret

A proxy server is a server that forwards the requests of a client to another server. Flux reads the proxy of a `GitRepository` from a Secret named in `spec.proxySecretRef`. The Secret has these keys:

| Key | Meaning |
| --- | --- |
| `address` | The proxy address, required. HTTP, HTTPS or SOCKS5 |
| `username` | The proxy user name, optional |
| `password` | The proxy password, optional |

SOCKS5 is a proxy protocol that forwards any TCP connection. A SOCKS5 proxy can be used with an `https://` Git URL. The proxy settings of the `GitRepository` win over the environment variables `HTTPS_PROXY` and `ALL_PROXY` of the controller, so one source can use a different proxy from the rest.

Create the Secret. This one has no credentials, and `proxy.example.com` is a name for the example only:

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system create secret generic fleet-proxy --from-literal=address=http://proxy.example.com:3128
```

Then read back the key names:

```sh
kubectl -n flux-system get secret fleet-proxy -o jsonpath='{.data}' | jq 'keys'
```

The result is the single key `address`. The Secret holds only the proxy, and the repository credentials stay in `spec.secretRef`.

## Reference the proxy

Save this as `gitrepository-fleet-proxy.yaml` to see the shape of the field. Do not apply it in the playground: the proxy name does not exist, and `fleet` would stop fetching.

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: fleet
  namespace: flux-system
spec:
  interval: 1m
  timeout: 90s
  url: https://git.example.com/gitops/fleet.git
  ref:
    branch: main
  secretRef:
    name: fleet-auth
  proxySecretRef:
    name: fleet-proxy
```

The proxy only applies to HTTP and HTTPS URLs. An SSH URL does not use `proxySecretRef`.

## The fetch timeout

`spec.timeout` is the longest time source-controller waits for the Git operations of one fetch. It is a duration such as `90s`, and the default is `60s`. A large repository or a slow proxy can need more. When the time runs out, the fetch fails and the source retries at the next interval.

You can read the current value from the cluster, with the default shown when the field is unset:

```sh
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.timeout}{"\n"}'
```

An empty result means the field is not set and the default of `60s` applies. To see the field described, use:

```sh
kubectl explain gitrepository.spec.timeout
```

Raise the timeout only after you know the fetch is slow, not stalled. A timeout that is too long hides a connection that never completes.

## Telling a proxy problem from a server problem

The condition message tells you where the connection stopped. A message that names the proxy address means the request did not reach Git. A message from the Git server, such as an authentication error, means the request passed through the proxy. Fix them in that order: first the `address`, then the credentials of the proxy, then the credentials of the repository.

You can now route one source through a proxy and bound its fetch time. Next come the credentials themselves, because tokens and provider identities replace passwords on most hosted Git services.

## Common pitfalls

> [!WARNING]
> - **Putting `HTTPS_PROXY` in the controller for one repository.** It changes every source. Use `proxySecretRef` for one.
> - **Expecting the proxy to apply to SSH.** `proxySecretRef` is for HTTP and HTTPS.
> - **Setting a very long timeout to hide a failure.** Find out why the fetch is slow first.
> - **Storing the repository password in the proxy Secret.** The two Secrets have different jobs.
