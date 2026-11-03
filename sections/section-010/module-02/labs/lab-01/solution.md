# Solution: Repair A Git SSH Connection

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: `fleet` is `Ready` on the SSH address with port 2222 and the Secret `fleet-ssh`, `known_hosts` holds a real host key of the Gitea server for `[gitea.localtest.me]:2222`, the key pair is unchanged and still a read-only deploy key, and `podinfo` applies the revision of `fleet`.

## Step 1: Read why fleet fails

```sh
flux get sources git
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.url}{"\n"}'
```

`fleet` is not `Ready`, and the message names a failed Git operation over SSH. The address `ssh://git@gitea.localtest.me/gitops/fleet.git` has no port, so source-controller connects to port 22, where nothing listens. That is the first cause.

## Step 2: Add the port to the address

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"url":"ssh://git@gitea.localtest.me:2222/gitops/fleet.git"}}'
flux reconcile source git fleet
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

The connection now reaches the server, and the message changes. It reports a host key problem: the key the server presented does not match the entry in `known_hosts`. That is the second cause.

## Step 3: Read the real host key

`ssh-keyscan` asks an SSH server for its public host keys. Run it in the `tester` pod, where `gitea.localtest.me` resolves to the Gitea Service:

```sh
kubectl -n gitea exec deploy/tester -- ssh-keyscan -p 2222 gitea.localtest.me
```

Lines that start with `#` are comments. Every other line has the form `[gitea.localtest.me]:2222 <type> <key>`. That is the format `known_hosts` needs for a server on a port other than 22.

## Step 4: Replace known_hosts and keep the key pair

Save the lines that do not start with `#` and put them into the Secret. Only `known_hosts` changes:

```sh
kubectl -n gitea exec deploy/tester -- ssh-keyscan -p 2222 gitea.localtest.me 2>/dev/null | grep -v '^#' > known_hosts
kubectl -n flux-system patch secret fleet-ssh --type=merge -p "{\"data\":{\"known_hosts\":\"$(base64 < known_hosts | tr -d '\n')\"}}"
flux reconcile source git fleet
```

## Step 5: Confirm the sync

```sh
flux get sources git
flux reconcile kustomization podinfo --with-source
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

`fleet` is `Ready` on `main@sha1:` and `podinfo` applies the same revision, with 2 ready replicas.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create a new key pair with `flux create secret git` | The new public key is not a registered deploy key, so the fetch fails with an authentication error and the grader fails the key check |
| Switch `fleet` to HTTP | The task keeps SSH, and the password Secret no longer exists |
| Remove `known_hosts` | source-controller refuses to connect without a host key to check |
| Write the entry without the port | The entry then belongs to port 22, not to `gitea.localtest.me:2222` |

## Practice on your own

- Break `known_hosts` again by editing one character and read the new message.
- Compare the lines `ssh-keyscan -t ed25519` and `-t rsa` return, and keep only one type in the Secret.
