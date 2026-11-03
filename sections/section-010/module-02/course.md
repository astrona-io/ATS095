# Secure Git Connections And Git Providers

A `GitRepository` that works against a test server over plain HTTP often fails on the first real Git server. The server uses a certificate from a private certificate authority, the cluster must reach it through a proxy, the provider refuses passwords, or the SSH host key changed. Each of these failures has a field or a Secret key that fixes it, and each shows up as a message in the conditions of the `GitRepository`.

A `GitRepository` is the Flux object that tells source-controller which Git repository to fetch. source-controller is the Flux controller that fetches sources and stores each fetched revision as an artifact. The way it connects is set by two places: the fields of `spec` (`url`, `timeout`, `provider`, `proxySecretRef`) and the keys of the Kubernetes Secret named in `spec.secretRef`.

Keep one sentence in mind: **the connection is described by the URL scheme and by the keys in the Secret, and a wrong or missing key is reported in the Ready condition.** The module teaches the keys for each kind of connection.

The module has four parts. **TLS Certificates For HTTPS Git Servers** shows the Secret keys `ca.crt`, `tls.crt` and `tls.key`. **HTTP Proxies And Timeouts** covers `proxySecretRef` and `spec.timeout`. **Tokens, Bearer Authentication And Git Providers** compares the Secret keys for tokens, for GitHub Apps and for cloud identity. **SSH Host Keys And known_hosts** explains how Flux checks the identity of an SSH server. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Name the Secret keys that give Flux a certificate authority and a client certificate for HTTPS.
- Configure a proxy for one `GitRepository` and set a fetch timeout.
- Choose between basic authentication, a bearer token, a GitHub App and cloud identity.
- Write a `known_hosts` entry for an SSH server on a port other than 22.
- Read a failed `GitRepository` condition and say whether the address, the Secret or the server is wrong.

## Before you start

You need Kubernetes basics (Secrets, `kubectl get`, `kubectl apply`, `kubectl patch`) and the basics of a `GitRepository` with a `Kustomization` that consumes it.

Your playground is a single-node `kind` cluster with **Flux v2.9.6** and Gitea, an in-cluster Git server, with the lab-only user `gitops` and the password `gitops-password`.

| What | Details |
| --- | --- |
| `gitops/fleet` | Private repository with `apps/podinfo`, tags `v1.0.0` and `v1.1.0`, and `main` |
| `gitops/platform` | Private repository with one file |
| `GitRepository` `fleet` | Follows `main` of `gitops/fleet` over HTTP with the Secret `fleet-auth` |
| Flux `Kustomization` `podinfo` | Applies `./apps/podinfo` from `fleet` |

The Git server answers at `http://gitea.localtest.me:3000` and `gitea.localtest.me:2222` (SSH). It uses no TLS and no proxy, so the playground cannot show a certificate or proxy error. You create the Secrets and read back their keys; the SSH checks run for real. On your machine the names work while a port-forward runs, so open a second terminal and leave this running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

If your router blocks the name, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
