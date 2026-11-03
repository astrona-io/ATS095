# Solution: Find Why A GitRepository Is Not Ready

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-02` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: `fleet` is `Ready` on `main` with its artifact in storage, `fleet` uses the existing Secret `fleet-auth`, the address is unchanged and no `release` branch was created, and `podinfo` applies the revision of `fleet` with 2 ready replicas.

## Step 1: Read the summary row

```sh
flux get sources git
```

`fleet` shows `READY` as `False`, and the message column holds the first problem. The summary shows one message only, so read the whole status next.

## Step 2: Read the conditions

```sh
kubectl -n flux-system describe gitrepository fleet
```

Look at the `Status` section and the events at the bottom. `Ready` is `False`, and the condition `FetchFailed` is `True`. Its message says that the Secret `fleet-credentials` was not found. The events repeat the same message at each retry. The same text is in the `GitRepository` itself: `spec.secretRef.name` is `fleet-credentials`.

## Step 3: List the Secrets and fix the name

```sh
kubectl -n flux-system get secrets
```

The Secret that exists is `fleet-auth`. The reference has a wrong name, so correct the reference. Do not create a new Secret:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"secretRef":{"name":"fleet-auth"}}}'
flux reconcile source git fleet
```

Source-controller now has credentials, but `fleet` is still not `Ready`.

## Step 4: Read the new message

```sh
kubectl -n flux-system get gitrepository fleet \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

The message has changed. It is now a Git error: the reference `refs/heads/release` cannot be found on the remote. The credentials work, because Git answers, but the branch `release` does not exist. List the branches of `gitops/fleet` with the Gitea API through the tester pod:

```sh
kubectl -n gitea exec deploy/tester -- curl -s -u gitops:gitops-password \
  http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/branches | jq -r '.[].name'
```

The repository has only `main`.

## Step 5: Fix the branch

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"ref":{"branch":"main"}}}'
flux reconcile source git fleet
flux get sources git
```

`fleet` is `Ready` on `main@sha1:` followed by the commit.

## Step 6: Confirm the sync

```sh
flux reconcile kustomization podinfo --with-source
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

`podinfo` is `Ready` on the revision of `fleet`, and the Deployment has 2 ready replicas. If the Flux `Kustomization` is still waiting, run the reconcile command once more.

## Step 7: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-02
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create a Secret named `fleet-credentials` | The grader fails it. A second Secret with the same password is one more place for it to leak, and `fleet-auth` already exists |
| Create a branch `release` in Gitea | The grader fails it. The error was in the `GitRepository`, not in the repository |
| Fix only the first problem | `fleet` stays `Ready False` with a different message. Read the message again after each fix |
| Delete and recreate `fleet` | It can work, but you learn nothing about the cause, and `podinfo` loses its source for a moment |

## Practice on your own

- Change the branch to `main` first and the Secret name second, and note which message you see first.
- Set `spec.suspend` to `true` with `flux suspend source git fleet` and read what `flux get sources git` shows. Resume it with `flux resume source git fleet`.
- Compare `flux events --for GitRepository/fleet` with the events at the bottom of `kubectl describe`.
