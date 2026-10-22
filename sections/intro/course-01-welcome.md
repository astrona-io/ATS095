# Welcome To The Course

This course trains you for the **Source Controller & Repository Management** part of the Astrona **FluxCD** training path. That part is 20% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, Services, Secrets, `kubectl apply`, `kubectl get` and `kubectl exec`. You can use Git from the terminal: clone, commit, tag and push. You have seen Flux deploy something from Git with a `GitRepository` and a Flux `Kustomization`, even if you do not know every field. Each new idea is explained the first time it appears.

## What you can do at the end

Every Flux delivery starts with a source: the object that tells source-controller where to fetch content from. This course does not ask you to remember field names. It asks you to make source-controller fetch exactly the right content, from the right place, with the right credentials, and to prove what it fetched. The course has four topics.

The first topic is **Git sources**. You will learn to:

- Pick a commit with a branch, a tag, a semver range, a full reference or a commit, and read the revision that proves it.
- Shape an artifact with ignore rules, and add files from a second repository with an include.
- Sign in with HTTPS credentials or a read-only SSH deploy key, and move from one to the other.

The second topic is **OCI sources**, manifests stored in a container registry. You will learn to:

- Push a folder as an OCI artifact with `flux push artifact` and list the releases.
- Follow a tag, a semver range or a digest with an `OCIRepository`.

The third topic is **Helm sources**. You will learn to:

- Read an HTTP Helm repository and an OCI chart registry with a `HelmRepository`.
- Resolve a chart version with a `HelmChart`, and find the one behind a `HelmRelease`.

The fourth topic is **bucket sources, triggers and artifacts**. You will learn to:

- Read manifests from an S3-compatible bucket with a `Bucket` source.
- Make Flux fetch now instead of at the next interval.
- Read the artifact source-controller stores, and explain how it garbage-collects older ones.

Everything is written for **Flux v2.9.6**.

## The words this course uses

The pages use Flux's, Git's, OCI's, Helm's and Kubernetes' own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **source** is a Flux object that tells source-controller where to fetch content from. **source-controller** is the Flux controller that fetches sources. Each time it fetches new content, it stores it as an **artifact**, a file it serves inside the cluster to the other Flux controllers, and reports a **revision** that names exactly what it fetched.

The course meets five kinds of source:

| Source | Where the content comes from |
| --- | --- |
| `GitRepository` | A branch, tag or commit of a Git repository |
| `OCIRepository` | A tag or digest of an artifact in a container registry |
| `HelmRepository` | An HTTP Helm repository or an OCI chart registry |
| `HelmChart` | One chart at one version, from one of the sources above |
| `Bucket` | A bucket on an S3-compatible object store |

The Flux `Kustomization` object, which applies an artifact to the cluster, is not the same thing as the Kustomize file `kustomization.yaml`, even though the names are alike. The pages always say which one they mean.

## The example setup in your playground

Every playground and lab deploys the same demo application, `podinfo`, a small web server, into the namespace `podinfo`. What changes between sections is where Flux reads it from. In the Git and OCI sections, a Git server called Gitea runs inside the cluster with the repository `gitops/fleet`, and the OCI section adds a container registry. The Helm section reads the public podinfo chart from the internet. The bucket section runs an S3-compatible server with a client pod for uploads.

The releases in a lab differ in their number of replicas, so the replica count of the `podinfo` Deployment tells you at a glance which release Flux applied. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections, one per kind of source, from the one you know best to the ones that are new.

| Section | What it covers |
| --- | --- |
| 010 | GitRepository In Depth |
| 020 | OCIRepository And Flux OCI Artifacts |
| 030 | HelmRepository And HelmChart |
| 040 | Bucket Sources, Triggers And Artifacts |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
