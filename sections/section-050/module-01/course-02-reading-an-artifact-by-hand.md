# Reading An Artifact By Hand

The artifact is a file, so you can fetch it like any other file. This part downloads one, looks inside, and checks the numbers in the status against the bytes.

## Why a helper pod

The Flux installation adds network policies to the namespace `flux-system`. They let pods of the same namespace talk to the controllers and block pods of other namespaces. A pod in `flux-system` can call the artifact server, so every command here runs in one. Paste the helpers in your terminal:

```sh
list_artifact_files() {
  ARTIFACT_URL="$(kubectl -n flux-system get gitrepository "$1" -o jsonpath='{.status.artifact.url}')"
  kubectl -n flux-system run artifact-reader --rm -i --restart=Never --quiet \
    --image=nicolaka/netshoot:v0.13 -- sh -c "curl -s '$ARTIFACT_URL' | tar -tzf -"
}
artifact_digest() {
  ARTIFACT_URL="$(kubectl -n flux-system get gitrepository "$1" -o jsonpath='{.status.artifact.url}')"
  kubectl -n flux-system run artifact-reader --rm -i --restart=Never --quiet \
    --image=nicolaka/netshoot:v0.13 -- sh -c "curl -s '$ARTIFACT_URL' | sha256sum"
}
```

## List the files

<!-- astrona:playground:renew -->

```sh
list_artifact_files fleet
```

You see the folders and files of the repository, without `.git/`. Files that the ignore rules leave out are missing here too. This list is exactly what a Flux `Kustomization` can use.

## Read the status next to the file

```sh
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact}' | jq
```

| Field | What it tells you |
| --- | --- |
| `revision` | The Git revision, for example `main@sha1:<commit>` |
| `digest` | `sha256:` followed by the hash of the `tar.gz` file |
| `url` | Where the file is served |
| `size` | The size of the file in bytes |
| `lastUpdateTime` | When source-controller last stored this artifact |

## Prove the digest

```sh
artifact_digest fleet
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.digest}{"\n"}'
```

The hash printed by `sha256sum` is the part of `digest` after `sha256:`. It is the hash of the archive, not of any single file inside it. This is why a consumer can check what it downloaded without trusting the network: if the bytes differ from the digest, the file is not the artifact the source reported.

## Count files, not folders

`tar -tvzf` prints a long listing. A line that starts with `-` is a regular file, and a line that starts with `d` is a folder:

```sh
kubectl -n flux-system run artifact-reader --rm -i --restart=Never --quiet --image=nicolaka/netshoot:v0.13 \
  -- sh -c "curl -s '$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.url}')' | tar -tvzf - | grep -c '^-'"
```

## Common pitfalls

- Hashing the output of `tar -tzf`. The digest belongs to the compressed file, so hash the bytes from `curl`.
- Running the commands from a pod outside `flux-system`. The request times out because of the network policies.
- Comparing digests of two different revisions. A new commit builds a new archive and a new digest, even when most files are the same.

## Your mission: Prove What source-controller Stored

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-095-playground-050-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-050/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-050/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-095-lab-050-01
astrona start ats-095-playground-050-01
```
