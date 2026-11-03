# Prerequisites

Before starting this lab you should be able to:

- Read the conditions and events of a `GitRepository`.
- Say what the keys `identity` and `known_hosts` of an SSH Secret do.
- Use `kubectl get`, `kubectl patch` and `flux reconcile`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). `gitea.localtest.me:2222` (SSH) works inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222` runs.
- A `tester` pod in the namespace `gitea` with `curl`, `jq` and the OpenSSH tools such as `ssh-keyscan`.
- The `GitRepository` `fleet`, the Secret `fleet-ssh` and the Flux `Kustomization` `podinfo`, all failing.

## Working rules

- Everything is graded on the **final state**, so check `flux get` at the end and leave the fix in place.
- Change one thing at a time and check again. Two causes mean two fixes, and the second error only appears after the first is gone.
