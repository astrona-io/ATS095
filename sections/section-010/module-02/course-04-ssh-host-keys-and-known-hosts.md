# SSH Host Keys And known_hosts

Over SSH, the client must know that it talks to the right server, or someone between the cluster and the server could answer in its place. SSH solves this with host keys. This part explains what source-controller checks, how the `known_hosts` key of the Secret is written for a server on port 2222, and how a mismatch looks. The graded lab that follows repairs one.

## What a host key is

A host key is the public key of an SSH server. The server proves that it owns the matching private key when the connection starts. The client compares the public key with the entry it holds for that server. If they differ, the client stops. This stops a man-in-the-middle attack, where another machine pretends to be the server.

For Flux, the entries live in the key `known_hosts` of the Secret in `spec.secretRef`. The Secret also holds the key `identity`, the private key of the client. If the private key has a password, a key `password` is added. The URL must use the form `ssh://user@host:port/path`. The short form `git@host:path` is not supported.

## Read the host keys of the playground server

`ssh-keyscan` connects to an SSH server and prints its public host keys. Run it in the `tester` pod, where `gitea.localtest.me` resolves to the Gitea Service:

<!-- astrona:playground:renew -->

```sh
kubectl -n gitea exec deploy/tester -- ssh-keyscan -p 2222 gitea.localtest.me
```

Lines that start with `#` are comments. Each other line has the host, the key type and the key. For a port other than 22, the host is written as `[gitea.localtest.me]:2222`, with square brackets around the name and the port after a colon. An entry written as `gitea.localtest.me` without the brackets belongs to port 22 and does not match a connection to port 2222.

Now compare with what Flux holds. Create a Secret for the second repository with `flux create secret git`, which reads the host key for you:

```sh
flux create secret git platform-ssh --url=ssh://git@gitea.localtest.me:2222/gitops/platform.git
kubectl -n flux-system get secret platform-ssh -o jsonpath='{.data.known_hosts}' | base64 -d
```

The command needs the port-forward from the module start, because `flux` runs on your machine. It generates a key pair, scans the host key and stores `identity`, `identity.pub` and `known_hosts`. It also prints the public key, which you register as a deploy key. The `known_hosts` value has the same host and key as `ssh-keyscan` printed.

## Key types and algorithms

An SSH server can hold host keys of several types: `ssh-ed25519`, `ecdsa-sha2-nistp256` and `ssh-rsa` are the common ones. The client and server must agree on one. The `known_hosts` entry must have a key of a type the server offers. `flux create secret git` has flags to choose the type of the client key (`--ssh-key-algorithm`) and the host key types it asks for (`--ssh-hostkey-algos`). Run it with `--help` to see the accepted values.

For a client key, ECDSA, Ed25519 and RSA are accepted. Choose the type the Git host allows, and keep one key per repository so that a deploy key reaches only one.

## When the host key changes

A server gets a new host key when it is reinstalled, or when an administrator rotates keys. source-controller then refuses the connection, because the stored key no longer matches. The condition message mentions the host key. Do not remove the check. Scan the server again, confirm through a channel you trust that the new key is the real one, and replace `known_hosts` in the Secret. A wrong port in the URL is the second common cause of an SSH failure, because the connection never reaches the SSH server. Fix the address first, then the key.

```sh
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

You can now read an SSH failure from the condition and say whether the address, the host key or the client key is wrong. The module has shown that every connection setting is a field of the `GitRepository` or a key of its Secret.

## Common pitfalls

> [!WARNING]
> - **Writing `known_hosts` without the port.** An entry for `host` is for port 22. Write `[host]:port` for any other port.
> - **Trusting a scanned key without checking it.** `ssh-keyscan` shows what answered. Compare it with a key you know.
> - **Replacing the key pair when only `known_hosts` is wrong.** The new public key then needs a new deploy key.
> - **Using the `git@host:path` URL.** Flux needs `ssh://git@host:port/path`.

## Your mission: Repair A Git SSH Connection

You can now tell an address problem from a host key problem and repair `known_hosts`. The graded lab gives you a `GitRepository` that moved to SSH and never fetched. It asks you to find the causes from its conditions, fix them without changing the key pair, and keep `podinfo` running from the same revision.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-095-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-095-lab-010-02
astrona start ats-095-playground-010-02
```
