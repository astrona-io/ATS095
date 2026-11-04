# How source-controller Stores And Serves Artifacts

When a `GitRepository` says `Ready`, a file now exists somewhere in the cluster. Every other Flux controller reads that file, not the Git server. If you can find the file and open it, a whole family of questions stops being guesswork: "Which commit did Flux really fetch?", "Why does the cluster still run the old version?", "What happens when source-controller restarts?"

source-controller is the Flux controller that fetches sources (Git, OCI, Helm, Bucket) and stores each fetched revision as an **artifact**: a `tar.gz` file of the files of that revision. It serves the artifact over HTTP, inside the cluster, to the controllers that need it. This module follows an artifact from the moment it is built to the moment it is read, and then deletes it, to see what remains.

Keep one sentence in mind: **the artifact is the contract between source-controller and the rest of Flux.** The source decides what goes in; the consumers see only what the file holds.

The module has four parts. **Where Artifacts Live** finds the storage folder, the artifact server and the shape of an artifact URL. **Reading An Artifact By Hand** downloads one, lists its files, and proves the digest in the status. A graded lab follows it, where you commit a change and record what source-controller stored. **Retention, Restarts And The Latest Artifact** explains garbage collection and what a restart does to the storage. **Who Reads The Artifact** follows the file to kustomize-controller and helm-controller and shows why other namespaces cannot reach it.

## Learning objectives

After this module you can:

- Say where source-controller keeps artifacts and how the other controllers reach them.
- Read an artifact URL and name its parts.
- Download an artifact from inside the cluster, list its files and compute its digest.
- Explain why `status.artifact.digest` equals the sha256 of the file the server sends.
- Describe what garbage collection keeps, and what a restart of the pod does.
- Follow an artifact from a source to a Flux `Kustomization` with `flux trace`.

## Before you start

You need the `GitRepository` and the Flux `Kustomization` from earlier sections, and `kubectl` basics. Your playground is a single-node `kind` cluster with **Flux v2.9.6**, Gitea with the lab-only user `gitops` and the password `gitops-password`, and the repositories `gitops/fleet` and `gitops/platform`. The `GitRepository` `fleet` follows `main` with the Secret `fleet-auth`, and the Flux `Kustomization` `podinfo` applies `./apps/podinfo`.

The Git server answers at `http://gitea.localtest.me:3000`. Inside the cluster this name already works. On your machine it works while a port-forward runs, so open a second terminal and leave this running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
