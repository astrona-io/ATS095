# HTTPS Credentials And SSH Deploy Keys

Both repositories in your playground are private, so source-controller must prove to Gitea that it may read them. Right now it does that with the password of the user `gitops`, an administrator who can also push to and delete every repository. If that Secret leaks, so does the whole Git server. This part looks at the two kinds of Git credentials Flux supports and replaces the password with an SSH deploy key: a key that can read one repository and do nothing else.

## What the password Secret holds

source-controller reads credentials from the Secret named in `spec.secretRef`. List the keys of the Secret `fleet-auth`, without printing the values:

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system get secret fleet-auth -o jsonpath='{.data}' | jq 'keys'
```

The Secret has two keys, `username` and `password`. That is **basic authentication**: source-controller sends the user name and the password with every request to the Git server. With a Git host such as GitHub or GitLab, the password is usually a personal access token with read access only. The Secret was created with `flux create secret git fleet-auth --url=… --username=… --password=…`, which writes exactly these two keys.

Basic authentication is meant for HTTPS, where TLS encrypts the password on the way. This lab Git server uses plain HTTP, so the password crosses the cluster network in clear text. That is acceptable only in a throwaway lab, and it is one more reason to move to SSH.

## How an SSH deploy key works

A **deploy key** is an SSH public key that the Git server attaches to one repository, not to a user. It can be read-only or read-write. Flux keeps the matching private key in a Secret, so the key reaches exactly one repository, and with `read_only` it cannot push.

An SSH Secret for Flux holds three keys:

| Key | What it is |
| --- | --- |
| `identity` | The private key source-controller uses to sign in |
| `identity.pub` | The public key; you register this one with the Git server |
| `known_hosts` | The public host key of the Git server, so source-controller can check it talks to the real server |

The `known_hosts` entry matters. Without it, a machine in the middle could pose as the Git server and serve other content. source-controller refuses an SSH connection to a host whose key is not in `known_hosts`.

## Create a key pair for the platform repository

`flux create secret git` with an `ssh://` address does three things in one command: it generates a key pair (ECDSA with the P-384 curve by default), connects to the server to read its host key, and stores all three values in a Secret. It also prints the public key, ready to register. The command connects from your machine, so the port-forward with port `2222` must be running in your second terminal.

The SSH address of a Gitea repository uses the user `git`, the host, the port and the repository path. Create the Secret for `gitops/platform`:

```sh
flux create secret git platform-ssh --url=ssh://git@gitea.localtest.me:2222/gitops/platform.git
```

The command prints a deploy key line that starts with `ecdsa-sha2-nistp384`, and creates the Secret `platform-ssh` in `flux-system`. Read the public key back from the Secret at any time, and keep it in a variable:

```sh
DEPLOY_KEY="$(kubectl -n flux-system get secret platform-ssh -o jsonpath='{.data.identity\.pub}' | base64 -d)"
echo "$DEPLOY_KEY"
```

## Register it as a read-only deploy key

Gitea now has to accept this key for `gitops/platform`. You can do it in the web page of the repository (Settings, then Deploy Keys), or with the Gitea API, which is easier to repeat. The request sends the key with `read_only` set to `true`:

```sh
curl -s -u gitops:gitops-password -X POST \
  -H 'Content-Type: application/json' \
  -d "{\"title\":\"flux-kind\",\"key\":\"$DEPLOY_KEY\",\"read_only\":true}" \
  http://gitea.localtest.me:3000/api/v1/repos/gitops/platform/keys | jq '{id, title, read_only}'
```

Gitea answers with the new key's `id`, its `title` and `read_only` as `true`. The administrator password is used here once, by you, to register the key. source-controller never sees it again.

## Move the GitRepository to SSH

Now change the `GitRepository` `platform` to the SSH address and the new Secret. Both fields change together; an SSH address with the password Secret, or the other way round, fails. Save this as `gitrepository-platform.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: platform
  namespace: flux-system
spec:
  interval: 5m
  url: ssh://git@gitea.localtest.me:2222/gitops/platform.git
  ref:
    branch: main
  secretRef:
    name: platform-ssh
```

Apply it:

```sh
kubectl apply -f gitrepository-platform.yaml
```

Then check the result:

```sh
flux reconcile source git platform
flux get sources git
```

`platform` is `Ready` on a `main@sha1:` revision, fetched over SSH with a key that can only read this one repository. Inside the cluster, `gitea.localtest.me` points at the Gitea Service, so source-controller reaches port `2222` without your port-forward. The host key it checks is the same one your machine read through the port-forward, because both connections end at the same Gitea server.

You can now read the two kinds of Git Secret, create an SSH key pair with its host key, register the public key as a read-only deploy key, and move a `GitRepository` to it. One step is left after a move like this: remove the password Secret, because a Secret nobody uses is still a Secret that can leak.

## Common pitfalls

> [!WARNING]
> - **Changing the URL and forgetting the Secret, or the other way round.** An `ssh://` address needs a Secret with `identity` and `known_hosts`; an `http://` or `https://` address needs `username` and `password`.
> - **Registering the private key.** Only `identity.pub` goes to the Git server. The private key `identity` never leaves the Secret.
> - **A read-write deploy key for reading.** Flux only reads from this repository. Give it a read-only key; write access is for tools that push, such as image automation.
> - **Creating the Secret without the port-forward.** `flux create secret git` reads the host key from your machine. Without the port-forward on port `2222`, it cannot connect.
> - **Leaving the old password Secret behind.** Delete it once nothing references it.

## Your mission: Move The GitRepository To An SSH Deploy Key

You can now move a `GitRepository` from a password to a read-only SSH deploy key. The graded lab gives you a cluster where `fleet` still reads `gitops/fleet` with the administrator password, and asks you to move it to a deploy key, keep `podinfo` running, and remove the password Secret.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-095-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-095-lab-010-01
astrona start ats-095-playground-010-01
```
