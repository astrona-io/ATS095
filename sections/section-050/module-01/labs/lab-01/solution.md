# Solution: Prove What source-controller Stored

Work the task yourself first. Running `astrona submit -c sections/section-050/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Change the replica count in Git

Edit `apps/podinfo/deployment.yaml` in `gitops/fleet` and set `replicas: 4`. With the port-forward running you can clone, edit, commit and push:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git /tmp/fleet
cd /tmp/fleet
sed -i.bak 's/replicas: 2/replicas: 4/' apps/podinfo/deployment.yaml && rm apps/podinfo/deployment.yaml.bak
git commit -am "Scale podinfo to 4 replicas" && git push origin main
```

## Step 2: Wait for the new artifact

```sh
flux reconcile source git fleet
flux reconcile kustomization podinfo
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.revision}{"\n"}'
```

The revision differs from the one in `lab-initial`: source-controller fetched the new commit, built a new tar.gz and stored it.

## Step 3: Read the artifact through artifact-reader

```sh
URL="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.url}')"
kubectl -n flux-system exec deploy/artifact-reader -- sh -c "curl -s '$URL' | sha256sum"
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.digest}{"\n"}'
kubectl -n flux-system exec deploy/artifact-reader -- sh -c "curl -s '$URL' | tar -tvzf - | grep -c '^-'"
```

The two digests are the same: the digest in the status is the sha256 of the tar.gz file the server sends. `tar -tvzf` lists the entries; lines that start with `-` are regular files, and lines that start with `d` are folders.

## Step 4: Write the proof

```sh
kubectl -n flux-system create configmap artifact-proof \
  --from-literal=revision="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.revision}')" \
  --from-literal=digest="sha256:<hex from step 3>" \
  --from-literal=files="<count from step 3>"
```
