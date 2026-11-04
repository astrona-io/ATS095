# Solution: Fix Failing Sources

Work the task yourself first. Running `astrona submit -c sections/section-050/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read all three sources

```sh
flux get sources git
kubectl -n flux-system get gitrepository -o custom-columns=NAME:.metadata.name,SUSPENDED:.spec.suspend,READY:.status.conditions[0].status,MESSAGE:.status.conditions[0].message
```

Three different pictures: `fleet` is not ready and the message is about a Git reference that cannot be found, `platform` is not ready and the message is an authentication failure, and `fleet-tags` shows as suspended with no recent activity.

## Step 2: fleet follows a branch that does not exist

```sh
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.ref}{"\n"}'
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"ref":{"branch":"main"}}}'
flux reconcile source git fleet
```

## Step 3: platform sends a wrong password

The Secret `platform-auth` holds a password Gitea rejects. Replace the Secret, keeping the name:

```sh
flux create secret git platform-auth \
  --url=http://gitea.localtest.me:3000/gitops/platform.git \
  --username=gitops --password=gitops-password --export | kubectl apply -f -
flux reconcile source git platform
```

## Step 4: fleet-tags is suspended

A suspended source is skipped. The status keeps its last values (here none), so nothing is reported as failing:

```sh
flux resume source git fleet-tags
```

## Step 5: Check the consumers

```sh
flux reconcile kustomization podinfo --with-source
flux reconcile kustomization platform-settings --with-source
flux get all
```
