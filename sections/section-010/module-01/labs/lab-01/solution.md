# Solution: Move The GitRepository To An SSH Deploy Key

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: `fleet` is `Ready` on the SSH address with `fleet-ssh`, `fleet-ssh` holds an SSH identity and `known_hosts` while `fleet-auth` is gone, the public key is a read-only deploy key of `gitops/fleet`, and `podinfo` still runs from the same revision.

## Step 1: Look at the current state

Check the source and what it uses to sign in:

```sh
flux get sources git
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.url}{"  "}{.spec.secretRef.name}{"\n"}'
kubectl -n flux-system get secret fleet-auth -o jsonpath='{.data}' | jq 'keys'
```

`fleet` is `Ready`, it reads `http://gitea.localtest.me:3000/gitops/fleet.git`, and its Secret `fleet-auth` holds `username` and `password`. That is the administrator's password, which the task replaces.

## Step 2: Create the SSH Secret

With the port-forward running in your second terminal, let the `flux` tool generate the key pair and read the host key of the Gitea SSH server:

```sh
flux create secret git fleet-ssh --url=ssh://git@gitea.localtest.me:2222/gitops/fleet.git
kubectl -n flux-system get secret fleet-ssh -o jsonpath='{.data}' | jq 'keys'
```

The Secret holds `identity`, `identity.pub` and `known_hosts`, and no password. The command also printed the public key. If it fails to connect, the port-forward is not running or `gitea.localtest.me` does not resolve to `127.0.0.1` on your machine.

## Step 3: Register the read-only deploy key

Read the public key from the Secret and send it to Gitea with `read_only` set to `true`:

```sh
DEPLOY_KEY="$(kubectl -n flux-system get secret fleet-ssh -o jsonpath='{.data.identity\.pub}' | base64 -d)"
curl -s -u gitops:gitops-password -X POST \
  -H 'Content-Type: application/json' \
  -d "{\"title\":\"flux-kind\",\"key\":\"$DEPLOY_KEY\",\"read_only\":true}" \
  http://gitea.localtest.me:3000/api/v1/repos/gitops/fleet/keys | jq '{id, title, read_only}'
```

Gitea answers with the key's `id` and `read_only` as `true`. The web page of the repository, under Settings and then Deploy Keys, works too.

## Step 4: Move the GitRepository

Change the address and the Secret together. Save this as `gitrepository-fleet.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: fleet
  namespace: flux-system
spec:
  interval: 1m
  url: ssh://git@gitea.localtest.me:2222/gitops/fleet.git
  ref:
    branch: main
  secretRef:
    name: fleet-ssh
```

Apply it:

```sh
kubectl apply -f gitrepository-fleet.yaml
```

Then check the result:

```sh
flux reconcile source git fleet
flux get sources git
```

`fleet` is `Ready` on `main@sha1:` and the same commit as before. Only the way source-controller signs in changed, not the content.

## Step 5: Remove the password Secret and confirm the sync

Nothing references `fleet-auth` any more, so delete it, then confirm that the Flux `Kustomization` still applies the same revision:

```sh
kubectl -n flux-system delete secret fleet-auth
flux reconcile kustomization podinfo --with-source
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

`podinfo` is `Ready` on the revision of `fleet`, and the Deployment has 2 ready replicas.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Keep `fleet-auth` "just in case" | The administrator password stays in the cluster, which is what the review flagged; the grader fails it |
| Register a read-write deploy key | Flux only reads; a key that can push is more access than it needs, and the grader checks `read_only` |
| Put `identity` and a `password` in one Secret | The Secret mixes two methods and still holds a password |
| Create a second `GitRepository` over SSH | `podinfo` still reads `fleet`, which still uses the password |

## Practice on your own

- Delete the deploy key in Gitea and watch the error `fleet` reports at its next fetch, then add it back.
- Remove the `known_hosts` key from `fleet-ssh` with `kubectl edit` and read the error. Recreate the Secret with `flux create secret git`.
- Compare `--ssh-key-algorithm=ed25519` with the default ECDSA key in `flux create secret git --export`.
