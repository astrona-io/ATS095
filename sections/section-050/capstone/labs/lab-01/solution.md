# Solution: Operate source-controller Capstone

Work the task yourself first. Running `astrona submit -c sections/section-050/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the state

```sh
flux get sources git
flux get kustomizations -A
kubectl -n flux-system get deployment source-controller -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}'
```

`fleet` is not ready (the branch `trunk` is not in the repository), `platform` shows as suspended, `team-b-apps` reports a blocked cross-namespace reference, and the args hold `--concurrent=1`.

## Step 2: Raise the concurrency

```sh
kubectl -n flux-system get deployment source-controller -o json | jq '
  .spec.template.spec.containers[0].args |=
    (map(select(startswith("--concurrent") | not)) + ["--concurrent=6"])' | kubectl replace -f -
kubectl -n flux-system rollout status deployment/source-controller
```

## Step 3: Repair the two sources

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"ref":{"branch":"main"}}}'
flux resume source git platform
flux reconcile source git fleet
flux reconcile source git platform
```

## Step 4: Give team B its own source

```sh
flux create secret git fleet-auth -n team-b \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git --username=gitops --password=gitops-password
flux create source git fleet -n team-b \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git --branch=main --secret-ref=fleet-auth --interval=1m
kubectl -n team-b patch kustomization team-b-apps --type=merge -p \
  '{"spec":{"serviceAccountName":"team-b","sourceRef":{"kind":"GitRepository","name":"fleet","namespace":"team-b"}}}'
flux reconcile kustomization team-b-apps -n team-b
```

## Step 5: Check

```sh
flux get sources git -A
flux get kustomizations -A
```
