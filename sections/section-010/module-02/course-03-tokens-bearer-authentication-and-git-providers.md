# Tokens, Bearer Authentication And Git Providers

Hosted Git services stopped accepting account passwords for Git over HTTPS. They want a token, a signed identity or a short-lived credential. This part compares the ways a `GitRepository` can prove who it is, and shows which Secret keys and which `spec.provider` value each one needs.

## Four ways to sign in

Every way is chosen by the Secret named in `spec.secretRef`, and some also by `spec.provider`. The table gives the whole picture before the details.

| Method | URL | Secret keys | `spec.provider` |
| --- | --- | --- | --- |
| Basic authentication | HTTPS | `username`, `password` | `generic` (default) |
| Bearer token | HTTPS | `bearerToken` | `generic` |
| GitHub App | HTTPS | `githubAppID`, `githubAppInstallationID` (or owner), `githubAppPrivateKey` | `github` |
| Cloud identity | HTTPS | none; uses a service account | `azure` (Azure DevOps) |
| SSH key | SSH | `identity`, `known_hosts` | `generic` |

Basic authentication sends a user name and a password in an `Authorization: Basic` header. A bearer token is a single secret string that the server accepts on its own. source-controller sends it in the header `Authorization: Bearer <token>` over HTTPS. Use it when the Git server documents bearer tokens.

## Personal access tokens use basic authentication

GitHub, GitLab and Bitbucket call their tokens personal access tokens, and they expect them in the password field of basic authentication. Create the Secret with a token in place of a password. The values below are lab-only:

<!-- astrona:playground:renew -->

```sh
flux create secret git platform-token --url=http://gitea.localtest.me:3000/gitops/platform.git --username=gitops --password=gitops-password
```

Read the key names back:

```sh
kubectl -n flux-system get secret platform-token -o jsonpath='{.data}' | jq 'keys'
```

The Secret holds `username` and `password`. For a bearer token, `kubectl create secret generic` with `--from-literal=bearerToken=<token>` builds the Secret with the one key `bearerToken`. A token should be read-only and limited to the repositories Flux needs.

## GitHub App authentication

A GitHub App is an identity registered in GitHub that is installed on an organization or user. Flux can sign in as the app and get a short-lived access token, so no long-lived token is stored. Set `spec.provider: github` and give the Secret these keys:

- `githubAppID` or `githubAppClientID`, exactly one of them.
- `githubAppInstallationOwner` or `githubAppInstallationID`, exactly one of them.
- `githubAppPrivateKey`, the private key of the app, required.
- `githubAppBaseURL`, only for GitHub Enterprise Server, for example `https://HOSTNAME/api/v3`.
- `ca.crt`, only for GitHub Enterprise Server with a private CA.

The command `flux create secret githubapp` builds such a Secret. Run it with `--help` to see its flags. Save this as `gitrepository-github-app.yaml` to see the shape; do not apply it, because the repository does not exist:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: fleet-github
  namespace: flux-system
spec:
  interval: 5m
  url: https://github.com/example-org/fleet.git
  provider: github
  ref:
    branch: main
  secretRef:
    name: github-app
```

The app needs read access to the repository contents only. The token lives for a short time, and source-controller asks for a new one when it needs it.

## Cloud identity

For Azure DevOps, `spec.provider: azure` makes source-controller use the identity of a Kubernetes service account instead of a stored secret. You set `spec.serviceAccountName` to a service account that is linked to an Azure identity (workload identity). The link is made in Azure and in the cluster, outside the `GitRepository`. A kind cluster has no cloud identity, so this method cannot run in the playground. The decision rule is the same as for the GitHub App: prefer a short-lived identity over a stored token when the platform offers one.

The documented values of `spec.provider` for a `GitRepository` are `generic`, `aws`, `azure` and `github`. Without the field, `generic` is used, and then only the Secret decides the method.

## Choosing a method

Choose in this order. Use a cloud identity or a GitHub App where the host supports it, because nothing long-lived sits in the cluster. Use a read-only deploy key over SSH for one repository. Use a read-only token when you need HTTPS. Use a password only for lab servers like the Gitea of this playground.

You can now match a Git host to a Secret and a provider. SSH has its own check of the server that the other methods do not have: the host key.

## Common pitfalls

> [!WARNING]
> - **Giving both `githubAppID` and `githubAppClientID`.** Give exactly one of each pair.
> - **Using a token with write access.** Flux only reads. A leaked token can then change the repository.
> - **Setting `provider: github` without a GitHub App Secret.** A password Secret does not work with this provider.
> - **Expecting `azure` to work on a cluster without workload identity.** There is no identity to use.
