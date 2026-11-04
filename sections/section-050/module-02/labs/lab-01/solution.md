# Solution: Tune source-controller

Work the task yourself first. Running `astrona submit -c sections/section-050/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the current arguments

```sh
kubectl -n flux-system get deployment source-controller -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}'
kubectl -n flux-system get deployment source-controller -o jsonpath='{.spec.template.spec.containers[0].resources}{"\n"}'
```

The list holds `--concurrent=1` and `--storage-path=/data` among others. Replace the old value; do not add a second one.

## Step 2: Rewrite arguments and resources

`kubectl edit deployment source-controller -n flux-system` works. The scripted form:

```sh
kubectl -n flux-system get deployment source-controller -o json | jq '
  .spec.template.spec.containers[0] |=
    ( .args |= ( map(select((startswith("--concurrent") or startswith("--artifact-retention")) | not))
                 + ["--concurrent=8","--artifact-retention-records=4","--artifact-retention-ttl=5m"] )
    | .resources.requests.memory = "256Mi"
    | .resources.limits.memory = "2Gi" )' | kubectl replace -f -
```

## Step 3: Wait for the rollout

```sh
kubectl -n flux-system rollout status deployment/source-controller
flux get sources git
flux get kustomizations
```

Changing the pod template restarts source-controller. Artifacts live in an `emptyDir` volume, so the new pod fetches every source again. Wait until `fleet` and `podinfo` are `Ready`.
