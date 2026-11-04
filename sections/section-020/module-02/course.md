# Authenticate To Registries And Verify OCI Artifacts

A registry on the public internet answers anyone, but the registry that holds your releases does not. It asks for a sign-in, it may use a private certificate, and you may want proof that a release was built by your pipeline and not by someone else. An `OCIRepository` has a field for each of these.

An **OCI registry** is the server that stores artifacts and answers pulls. A **pull secret** is a Kubernetes Secret of the type `kubernetes.io/dockerconfigjson` with the credentials for one registry address. A **signature** is a cryptographic proof, stored next to the artifact in the registry, that a key holder signed this exact digest.

Keep one sentence in mind: **the credentials are found by the registry address, so the address in the Secret and the address in the `url` must match.**

The module has four parts. **Registry Credentials With A Pull Secret** signs in with `secretRef` and reads a 401 error. **ServiceAccount And Cloud Identity** gives a whole service account the credentials and explains the cloud providers. **TLS Certificates And Proxies** covers `certSecretRef` and `proxySecretRef`. **Verify Signatures With cosign** checks signatures with `spec.verify`. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Create a pull secret with `flux create secret oci` and use it from an `OCIRepository`.
- Read the authentication error of a registry and tell a missing Secret from a wrong password.
- Give a service account the credentials with `serviceAccountName` and `imagePullSecrets`.
- Say which `provider` value fits each cloud registry, and what workload identity replaces.
- Add a CA certificate with `certSecretRef` and a proxy with `proxySecretRef`.
- Turn on `spec.verify` with cosign and read the condition `SourceVerified`.

## Before you start

You need the basics of an `OCIRepository` and a Secret, and `flux push artifact` from the previous module.

Your playground is a single-node `kind` cluster with **Flux v2.9.6**, Gitea and an OCI registry that requires a sign-in.

| Service | Details |
| --- | --- |
| Gitea | Git server with the private repository `gitops/fleet` (user `gitops`, password `gitops-password`) |
| OCI registry | `registry.localtest.me:5001`, plain HTTP, user `flux`, password `registry-password`. Holds `podinfo-manifests:1.0.0` (1 replica) and `podinfo-manifests:1.1.0` (3 replicas) |

On your machine the registry answers while a port-forward runs, so open a second terminal and leave this running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 &
kubectl -n registry port-forward svc/registry 5001:5001
```

If your router blocks the names, add `127.0.0.1 gitea.localtest.me registry.localtest.me` to `/etc/hosts`. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
