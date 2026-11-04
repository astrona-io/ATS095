# Tune And Size source-controller

The default installation of source-controller is made for a small cluster. It reconciles a few sources at a time, keeps a few artifacts and has a modest memory limit. That is the right start, and it stops being right when the cluster has hundreds of sources, large repositories or Helm repositories with big indexes. Then the symptoms are quiet: sources that fetch late, an `OOMKilled` pod, a disk that fills.

This module treats source-controller as a workload you size. It names what makes the controller busy, the flags that change how it works, the resources that bound it, and the right way to make a change stick so that a bootstrap does not undo it.

Keep one sentence in mind: **every source is a unit of work, and `--concurrent` says how many run at once.** The rest of the module follows from that.

The module has four parts. **What Makes source-controller Busy** counts the work and finds the signs of too little capacity. **Flags For Concurrency, Retention And Caches** goes through the flags that matter. **Resources, Limits And Restarts** reads `OOMKilled` and explains what a restart costs. A graded lab follows it, where you tune a slow source-controller. **Making Changes Stick And Sharding** moves the change into Git and shows how label selectors split the work between several controllers.

## Learning objectives

After this module you can:

- List what a source costs source-controller: a fetch, an archive, a stored file and a status update.
- Read the args and resources of the Deployment and change them safely.
- Say what `--concurrent`, `--artifact-retention-records` and `--artifact-retention-ttl` do.
- Recognise an `OOMKilled` source-controller and choose a memory limit.
- Explain why a `kubectl edit` is undone by a bootstrap, and make the change in Git.
- Describe sharding with `--watch-label-selector`.

## Before you start

You need the artifact model from the previous module. Your playground is a single-node `kind` cluster with **Flux v2.9.6**, Gitea with the lab-only user `gitops` and the password `gitops-password`, and the repositories `gitops/fleet` and `gitops/platform`. The `GitRepository` `fleet` follows `main` and the Flux `Kustomization` `podinfo` applies `./apps/podinfo`. The cluster has no metrics-server, so use `describe` and the events for resource facts.

The Git server answers at `http://gitea.localtest.me:3000`. Inside the cluster this name already works. On your machine it works while a port-forward runs, so open a second terminal and leave this running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
