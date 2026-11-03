# Control What source-controller Fetches From Git

A `GitRepository` that says `branch: main` deploys whatever someone merged five minutes ago. That is fine for a test cluster and risky for production, where you want a released version. The same object also decides which files reach the cluster and which credentials Flux sends to the Git server. All three choices sit in a few lines of YAML.

A `GitRepository` is the Flux object that tells source-controller which Git repository to fetch, which commit, and how often. source-controller is the Flux controller that fetches sources and stores each fetched commit as an **artifact**: a `tar.gz` file of the files of that commit, which it serves inside the cluster to the other Flux controllers. The `GitRepository` `fleet` in your playground already works; this module takes its fields apart.

Keep one sentence in mind: **the revision in `flux get sources git` is the answer to "what exactly did Flux fetch?"** Every change you make in this module shows up there first.

The module has five parts. **Choosing A Git Reference** compares the five ways to pick a commit and moves `fleet` from a branch to a semver range of release tags. **Shaping The Artifact With ignore And include** opens an artifact, shows what the default rules leave out, and adds files from a second repository. **HTTPS Credentials And SSH Deploy Keys** looks at the two kinds of Git credentials and moves `fleet` to a read-only SSH key. A graded lab follows it. **GitRepository Status, Conditions And Events** reads the conditions, the artifact and the events of a source, and matches common failure messages to their causes. A second graded lab follows it, where you find and fix a source that cannot fetch. **Managing Git Sources With The Flux CLI** creates, exports, reconciles, suspends and resumes a source from the command line, and explains `spec.interval`, `spec.timeout` and `spec.suspend`.

## Learning objectives

After this module you can:

- Choose a `branch`, `tag`, `semver`, `name` or `commit` reference, and say which one wins when several are set.
- Read a revision such as `main@sha1:<commit>` or `v1.1.0@sha1:<commit>` and say where it came from.
- Write a semver range that follows one release line and skips the next major version.
- List the files in an artifact and explain why some files of the commit are missing.
- Leave files out with `.sourceignore` or `spec.ignore`, and add files from a second repository with `spec.include`.
- Create a Secret for HTTPS basic authentication and one for SSH, and say which keys each holds.
- Register an SSH public key as a read-only deploy key and move a `GitRepository` to it.
- Read the conditions, `status.artifact`, `observedGeneration` and events of a `GitRepository`, and match a failure message to its cause.
- Create, export, reconcile, suspend and resume a `GitRepository` with the `flux` tool, and set `spec.interval` and `spec.timeout`.
- Follow a Deployment back to its source and revision with `flux trace`.

## Before you start

You need Kubernetes basics (namespaces, Deployments, Secrets, `kubectl get` and `kubectl apply`) and Git from the terminal (clone, commit, tag, push). You should know that a `GitRepository` feeds a Flux `Kustomization`, the Flux object that applies one folder of an artifact to the cluster.

Your playground is a single-node `kind` cluster with **Flux v2.9.6** and the `flux` command-line tool. It also runs Gitea, an in-cluster Git server, with the lab-only user `gitops` and the password `gitops-password`.

| What | Details |
| --- | --- |
| `gitops/fleet` | Private repository. `apps/podinfo` (the podinfo application), `clusters/kind`, and a `docs` folder. Tag `v1.0.0` asks for 1 replica, tag `v1.1.0` for 2, and `main` for 3 |
| `gitops/platform` | Private repository with one file, `podinfo-settings/configmap.yaml` |
| `GitRepository` `fleet` | Follows `main` of `gitops/fleet` over HTTP, with the Secret `fleet-auth` |
| Flux `Kustomization` `podinfo` | Applies `./apps/podinfo` from `fleet` |

The Git server answers at `http://gitea.localtest.me:3000` (HTTP) and `gitea.localtest.me:2222` (SSH). Inside the cluster these names already work. On your machine they work while a port-forward runs, so open a second terminal now and leave this running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

The name `gitea.localtest.me` is a public DNS name that points at `127.0.0.1`, so the port-forward answers it. If your router blocks such answers, add the line `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
