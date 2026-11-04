# Troubleshoot Failing Sources

A failing source is the most common Flux problem, and it has a useful property: it tells you what is wrong, in words, in the same place every time. The skill is reading that place in the right order, and then changing one thing.

This module gives the order. It starts with a method that works for every kind of source, goes through the messages of Git, OCI, Helm and Bucket sources and their causes, then looks at the sources that fail silently: the suspended and the stalled ones. The last part is about fixing safely and proving the fix reaches the cluster.

Keep one sentence in mind: **read the condition, then the events, then the log, and change one thing at a time.** Each step answers a narrower question than the one before.

The module has four parts. **A Method: Read, Narrow, Fix** sets the order and the commands. **What The Messages Mean** maps messages to causes for the four source kinds. **Suspended, Stalled And Silent Sources** covers the sources that report nothing wrong. A graded lab follows it, where you repair three sources with three different causes. **Fixing Safely And Proving It** finishes with the consumers and `flux trace`.

## Learning objectives

After this module you can:

- Read the `Ready` condition, `observedGeneration`, the events and the controller log for a source.
- Tell a failing source from a stalled one and from a suspended one.
- Match common messages for Git, OCI, Helm and Bucket sources to their causes.
- Fix a missing reference, a wrong credential and a suspension without recreating the objects.
- Prove that a Flux `Kustomization` applies the revision of the repaired source.

## Before you start

You need the conditions of a `GitRepository` from section 010. Your playground is a single-node `kind` cluster with **Flux v2.9.6**, Gitea with the lab-only user `gitops` and the password `gitops-password`, and the repositories `gitops/fleet` and `gitops/platform`. The `GitRepository` `fleet` follows `main` with the Secret `fleet-auth`, and the Flux `Kustomization` `podinfo` applies `./apps/podinfo`.

The Git server answers at `http://gitea.localtest.me:3000`. Inside the cluster this name already works. On your machine it works while a port-forward runs, so open a second terminal and leave this running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
