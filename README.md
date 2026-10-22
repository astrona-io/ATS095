# ATS095 — Source Controller & Repository Management (FluxCD)

Course material for the **Source Controller & Repository Management** domain
of the Astrona FluxCD training path ([ATP019](https://github.com/astrona-io/ATP019)),
which is **20% of the path**. Written for **Flux v2.9.6**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Flux v2.9 documentation. None has been started on a cluster, and
> no lab has passed `astrona test` yet. See `CLAUDE.md` for the open risks,
> in the order to check them.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **A module** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | GitRepository In Depth | 1 | 1 + capstone | Git sources and authentication |
| [020](sections/section-020) | OCIRepository And Flux OCI Artifacts | 1 | 1 + capstone | OCI sources |
| [030](sections/section-030) | HelmRepository And HelmChart | 1 | 1 + capstone | Helm sources |
| [040](sections/section-040) | Bucket Sources, Triggers And Artifacts | 1 | 1 + capstone | Bucket sources, triggers, artifacts |

The order follows the kinds of source, from the one learners know best (Git)
to the ones that are new. Section 040 also covers what applies to every
source: reconciliation triggers and the artifacts source-controller stores.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Control What source-controller Fetches From Git](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Deliver Manifests As OCI Artifacts](sections/section-020/module-01/course.md) | 2 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Fetch Helm Charts With source-controller](sections/section-030/module-01/course.md) | 2 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 040-01 | [Sync From A Bucket And Control When Flux Fetches](sections/section-040/module-01/course.md) | 2 | [lab-01](sections/section-040/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Pin A Release Line And Trim The Artifact | an open semver range that picks a broken `v2.0.0`, a `docs` folder in the artifact |
| [020](sections/section-020/capstone/labs/lab-01) | Repair An OCI Delivery | a tag in the `url`, no `insecure` for an HTTP registry, no `ref`, a Flux Kustomization that names a `GitRepository` |
| [030](sections/section-030/capstone/labs/lab-01) | Make A HelmRelease's Chart Resolve | a wrong repository address, a source name that does not exist, a version range with no match |
| [040](sections/section-040/capstone/labs/lab-01) | Repair A Bucket Source | wrong Secret key names, a wrong bucket name, no `insecure`, a wrong path |

---

## The lab environments

| Section | Services in the cluster | Reached from the machine at |
| --- | --- | --- |
| 010 | Gitea (HTTP and SSH) | `http://gitea.localtest.me:3000`, `gitea.localtest.me:2222` |
| 020 | Gitea, an OCI registry (`registry:3.1.2`) | the above, plus `registry.localtest.me:5001` |
| 030 | none; the podinfo chart comes from the internet | — |
| 040 | versitygw (S3-compatible) and an `aws` client pod | — (used through `kubectl exec`) |

The `*.localtest.me` names resolve to `127.0.0.1`, so a port-forward on the
machine answers them; inside the cluster a CoreDNS `rewrite stop` block sends
each name to its Service and rewrites the answer back. Every environment's
plumbing (manifests, bootstrap, testing, solution and validation scripts,
`config.yaml`, author READMEs, prerequisites) shares the same building blocks,
so a change to a shared piece must be made in every environment.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final state** with independent checks, and several of
them deliberately reject the plausible-but-wrong fix (pinning a commit or a
digest instead of fixing a range, keeping a password next to an SSH key,
shortening an interval instead of requesting a reconciliation, deleting and
recreating a source).
