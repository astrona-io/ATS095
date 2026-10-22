# Get Your Machine Ready

Every playground and lab in this course runs on your own machine, in a small Kubernetes cluster. A tool called `astrona` builds it for you, sets it up, grades your work and removes it again. This page gets your machine ready: first the tools you need, then the handful of `astrona` commands you will use every day, and last what to do when a start goes wrong.

## What you need

Every section needs the same set of tools. Install these before you start:

- **A container engine:** Docker or Podman. The cluster runs inside it.
- **`kind`:** runs Kubernetes inside the container engine. Flux 2.9 needs Kubernetes 1.34.1 or later, so use a recent `kind` release.
- **`kubectl`:** talks to the cluster.
- **`git`:** you clone repositories, tag releases and push from your own machine.
- **`flux`:** the Flux command-line tool. Each playground and lab also installs version 2.9.6 of it, so the version always matches the controllers.
- **`curl`** and **`jq`:** call the Gitea and registry APIs and pick fields out of their JSON answers.
- **The astrona command-line tool.**

The playgrounds and labs also need **outbound internet** while they start: they download the Flux command-line tool from GitHub and the images from public registries. The Helm section needs it the whole time, because the podinfo chart comes from the internet.

## Reaching the services in the cluster

Some services run inside the cluster: a Git server in the Git and OCI sections, and a container registry in the OCI section. Your machine reaches them through port-forwards. Every page that needs them asks you to start them in a second terminal and leave them running, for example:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222
```

The addresses are the same on your machine and inside the cluster: `http://gitea.localtest.me:3000` for Git over HTTP, `gitea.localtest.me:2222` for Git over SSH, and `registry.localtest.me:5001` for the registry. The names are public DNS names that point at `127.0.0.1`, your own machine, so the port-forward answers them. Inside the cluster, the same names point at the services.

Some home routers block DNS answers that point at `127.0.0.1`. If a name does not resolve, add this line to `/etc/hosts` on your machine:

```
127.0.0.1 gitea.localtest.me registry.localtest.me
```

These services use plain HTTP and lab-only credentials (Gitea user `gitops`, password `gitops-password`). A real Git server, registry or object store uses HTTPS and real credentials.

You do not have to check your tools by hand. Let `astrona` look at your machine for you:

```sh
astrona setup
```

`astrona setup` looks at what is missing, shows you each step it would take, and asks before it does anything. On macOS it can install `kind`, `kubectl` and Podman. Install `git`, `flux` and `jq` yourself.

Later, you can check your machine at any time:

```sh
astrona check
```

## The commands you use every day

Once your machine is ready, you need only a handful of `astrona` commands. Each module page and lab page shows the exact command to copy, so you do not need to remember paths. This section walks through them in the order you meet them: sign in, start, pause, submit and clean up.

Labs from the course catalog are tied to your Astrona account, so you sign in first:

```sh
astrona login
```

Next you start a playground or a lab. Each module page and lab page shows the exact `astrona run` command for it. It looks like this:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-010/module-01/playground
```

When the cluster is ready, `kubectl` already points at it.

A chapter that sends you to a lab asks you to pause the playground first. Pausing frees your machine's memory but keeps everything you built:

```sh
astrona stop <name>
```

When the lab is done, start the playground again and carry on where you left off:

```sh
astrona start <name>
```

Inside a lab, you send your work for grading with `astrona submit`. The grader checks the live cluster. It reads the Flux sources, the revisions they fetched and the running application, so your fix has to actually work, not only make an error message go away. Each lab page shows the exact command:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

You can submit as often as you like.

When you are done with a playground or a lab, remove it:

```sh
astrona destroy <name>
```

The name is the environment's name, printed by `astrona run` and shown on each page (for example `ats-095-playground-010-01`). It is not the folder path. To see what is on your machine, list it:

```sh
astrona list
```

> [!WARNING]
> **Run one environment at a time.** Each playground and lab is a whole cluster with its own Flux and services. Two running at once can use up your machine's memory, and it is easy to send a command to the wrong one. Pause or destroy the playground before you start the lab.

## When a start goes wrong

Sometimes a playground or lab does not start cleanly. Ask `astrona` what is wrong before you try anything else:

```sh
astrona doctor
```

It checks your machine, the lab's configuration and the running lab, and tells you how to fix what it finds.

If a start fails while it downloads something, check your network first. If `git`, `curl` or `flux push artifact` cannot reach a service, check that the port-forward is still running in your second terminal; it stops when the playground restarts. Remember also that a lab that starts with sources that are not `Ready` is often broken on purpose: the lab's task tells you when that is the case. With your machine ready and these commands at hand, you can start the first module.
