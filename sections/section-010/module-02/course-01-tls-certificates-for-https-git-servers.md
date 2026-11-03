# TLS Certificates For HTTPS Git Servers

Most company Git servers use HTTPS with a certificate signed by a private certificate authority (CA). A CA is the party whose signature makes a certificate trusted. source-controller runs in a container that does not know your private CA, so the first fetch fails with a certificate error. This part shows which Secret keys give Flux the CA, and a client certificate when the server asks for one.

## How source-controller checks a server

When a `GitRepository` has an `https://` URL, source-controller opens a TLS connection. TLS (Transport Layer Security) encrypts the connection and lets the client check the identity of the server. The server sends its certificate, and source-controller checks that a trusted CA signed it and that the certificate is valid for the host name in the URL.

The container image of source-controller trusts the public CAs only. A certificate from a private CA fails this check. The condition then reports a Git operation failure that mentions an unknown authority. Flux never skips the check by default.

## The three keys

The Secret that `spec.secretRef` names can carry TLS material next to, or instead of, credentials. Three keys matter:

| Key | What it holds |
| --- | --- |
| `ca.crt` | The CA certificate, in PEM format, that signed the server certificate |
| `tls.crt` | A client certificate, in PEM format, for mutual TLS |
| `tls.key` | The private key of the client certificate |

Mutual TLS means the server also checks the client. It is used when the Git server only accepts clients that hold a certificate. If `tls.crt` and `tls.key` are present, source-controller uses them. If the server needs no client certificate, leave them out.

## Create the Secret

`flux create secret tls` builds a Secret with these keys from files. The key names are fixed, so a different name in your own file changes nothing. Create the Secret from a CA file you hold, here `ca.pem`:

<!-- astrona:playground:renew -->

```sh
flux create secret tls fleet-ca --ca-crt-file=ca.pem --tls-crt-file=client.pem --tls-key-file=client-key.pem
```

The command stores the three files under `ca.crt`, `tls.crt` and `tls.key`. Without a client certificate, `kubectl create secret generic` with `--from-file=ca.crt=ca.pem` builds the same Secret with one key. Read the key names back, never the values:

```sh
kubectl -n flux-system get secret fleet-ca -o jsonpath='{.data}' | jq 'keys'
```

The result lists the key names you stored. Nothing in the playground uses the Secret, because Gitea runs without TLS. A `GitRepository` that fetches over HTTPS and needs the CA, with basic authentication too, uses one Secret with `username`, `password` and `ca.crt`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: fleet
  namespace: flux-system
spec:
  interval: 1m
  url: https://git.example.com/gitops/fleet.git
  ref:
    branch: main
  secretRef:
    name: fleet-auth
```

This file is only an example of the shape, so do not apply it here: `git.example.com` does not exist. The point is that one Secret reference carries the credentials and the trust.

## Where a certificate error shows up

A failed TLS check is reported in the `Ready` condition of the `GitRepository`, and the `Kustomization` that uses it waits for the source. Read it with:

```sh
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

Three messages are common. An unknown authority means `ca.crt` is missing or holds the wrong CA. A host name mismatch means the certificate is valid but not for the name in the URL, so the URL must use the name in the certificate. An expired certificate means the server, not Flux, needs a new certificate.

You can now give Flux trust in a private CA and a client certificate. The next question is how the connection leaves the cluster at all: many networks only allow outgoing traffic through a proxy.

## Common pitfalls

> [!WARNING]
> - **Putting the CA in a Secret in another namespace.** The Secret must be in the namespace of the `GitRepository`.
> - **Adding `tls.crt` without `tls.key`.** Mutual TLS needs both keys.
> - **Using an `http://` URL and expecting TLS settings to apply.** TLS keys only apply to `https://` URLs.
> - **Trying to turn the check off.** The `GitRepository` has no field for it. Fix the CA or the host name.
