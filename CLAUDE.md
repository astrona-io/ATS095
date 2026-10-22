# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS095 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Source Controller & Repository Management**
  domain of the **FluxCD** training path (`ATP019`). It is 20% of the path.
  There is no official Flux certification exam; the path's domains and weights
  are Astrona's own, set in `ATP019/path.yaml`.
- **What the domain really tests:** making source-controller fetch exactly the
  right content, from the right place, with the right credentials, and knowing
  what it produced. The student must *do* things (pin a `GitRepository` to a
  semver range, switch it to an SSH deploy key, push manifests to a registry
  with `flux push artifact`, follow a release line with an `OCIRepository`,
  make a `HelmChart` resolve, sync from a bucket, trigger a reconcile now).
  Every explanation should lead to a command they can run, and every fix
  should be proved with a source that is `Ready` on the expected revision and
  a workload that matches it.
- **The four topics:** Git sources, OCI sources, Helm sources, and bucket
  sources with reconciliation triggers and artifacts. The README table maps
  each section to its topic.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | GitRepository In Depth | Git sources and authentication |
  | 020 | OCIRepository And Flux OCI Artifacts | OCI sources |
  | 030 | HelmRepository And HelmChart | Helm sources |
  | 040 | Bucket Sources, Triggers And Artifacts | Bucket sources, triggers, caching |

- **The version:** everything is written for **Flux v2.9.6** (CLI and
  controllers) on a single-node `kind` cluster (Kubernetes 1.34.1 or later).
  Do not teach fields, flags or output from other versions without saying so.
- **The main sources:** the Flux documentation, <https://fluxcd.io/flux/>,
  in particular the source API pages. Check every page against them.

### Status: built, not yet run

The first version of this repository was written from the Flux v2.9
documentation **without a live run**. No playground or lab has been started,
and no `astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

The open risks, in the order to check them:

1. **Git credentials over plain HTTP.** The Flux documentation describes
   basic authentication for HTTPS only, and the repository `gitops/fleet` is
   private. If source-controller or `flux create secret git` refuses the
   `gitops` credentials over `http://gitea.localtest.me:3000`, every
   environment fails at the first fetch. The fallback is Gitea on HTTPS with a
   self-signed certificate.
2. **Gitea's built-in SSH server** in the rootless image, with the settings
   in `lab-start.yaml` (`START_SSH_SERVER`, port `2222`), and whether
   `flux create secret git` scans the host key from the reader's machine
   through the port-forward (the section 010 pages assume it does).
3. **The S3 server.** MinIO no longer publishes container images, so section
   040 uses `versity/versitygw:v1.9.0` with the posix backend
   (`ROOT_ACCESS_KEY`, `ROOT_SECRET_KEY`, `--port :9000 posix /data`) and
   `amazon/aws-cli:2.38.4` as the client. Check that a bucket created with
   `aws s3 mb` works on an `emptyDir` and that the Bucket source accepts it.
4. **The registry** `registry:3.1.2` on Service port `5001` (macOS uses port
   `5000` for AirPlay), and `flux push artifact --insecure-registry` against
   it. `flux tag artifact` documents no `--insecure-registry` flag, so pages
   describe tagging in words and never run it against this registry.
5. **Network policies.** `flux install` creates network policies that block
   traffic into the Flux controllers from other namespaces. Pages read an
   artifact with a short-lived pod in `flux-system`, never from `tester`.

### Terms, not metaphors

Explanations use Flux's, Git's, OCI's, Helm's and Kubernetes' own words.
Define each one in plain technical language on first use in a file, for
example:

| Term | First-use definition (example wording) |
| --- | --- |
| Source | A Flux object that tells source-controller where to fetch content from: `GitRepository`, `OCIRepository`, `HelmRepository`, `HelmChart` or `Bucket` |
| source-controller | The Flux controller that fetches sources and stores each revision as an artifact |
| Artifact | A `tar.gz` file (or a Helm index or chart) of one source revision that source-controller serves over HTTP inside the cluster |
| Revision | The exact version an artifact holds: `main@sha1:<commit>` for a branch, `<tag>@sha256:<digest>` for an OCI tag, `sha256:<digest>` for a bucket, the chart version for a `HelmChart` |
| Git reference (`spec.ref`) | Which commit a `GitRepository` follows: `branch`, `tag`, `semver`, `name` or `commit`; later fields win |
| Semver range | A version constraint such as `>=1.0.0 <2.0.0`; source-controller picks the highest version that matches |
| `.sourceignore` / `spec.ignore` | Files in `.gitignore` format that leave paths out of an artifact |
| `spec.include` | Copies the artifact of another `GitRepository` into this one's artifact |
| Basic authentication | A Secret with the keys `username` and `password` |
| SSH deploy key | An SSH key pair that gives access to one repository only; Flux keeps the private key as `identity` and the server's host key as `known_hosts` |
| OCI artifact | Content stored in a container registry the same way as an image; a Flux OCI artifact holds Kubernetes manifests as one compressed layer |
| `flux push artifact` | Packs a folder into an OCI artifact and pushes it to a registry, with the source URL and revision as annotations |
| Digest | The `sha256` hash of an OCI manifest; it never changes for the same content, while a tag can be moved |
| `HelmRepository` | A Helm chart repository: `type: default` downloads the `index.yaml`; `type: oci` only holds the registry address and has no status |
| `HelmChart` | One chart, at a version or range, from a `HelmRepository`, `GitRepository` or `Bucket`; helm-controller creates one for each `HelmRelease` |
| `Bucket` | An S3-compatible bucket; `provider: generic` uses a Secret with `accesskey` and `secretkey` |
| Reconcile request | `flux reconcile source …` or the annotation `reconcile.fluxcd.io/requestedAt`; it makes the controller run now instead of at the next interval |
| Garbage collection | source-controller deletes older artifacts; by default it keeps 2 (`--artifact-retention-records`) and removes older ones after 1 minute (`--artifact-retention-ttl`) |

On first use in a file, always say which `Kustomization` you mean: "the Flux
`Kustomization` object" or "the Kustomize file `kustomization.yaml`".

### The example workloads

| Name | Image | What it is |
| --- | --- | --- |
| `gitea` (Deployment, Service `gitea-http`, namespace `gitea`) | `gitea/gitea:28.2.0-rootless` | In-cluster Git server. HTTP on port `3000`, built-in SSH server on port `2222`. SQLite on an `emptyDir`, so a restart loses every repository |
| Gitea user `gitops` | | Password `gitops-password`, administrator. Lab-only credentials; say so when a page uses them |
| Repository `gitops/fleet` | | Private. Seeded per module (`apps/podinfo`, `clusters/kind`, sometimes `docs/` and tags) |
| `registry` (Deployment and Service, namespace `registry`) | `registry:3.1.2` | OCI registry over plain HTTP, Service port `5001`, section 020 only. The section 020 capstone runs only the registry, without Gitea |
| `versitygw` (Deployment, Service `s3`, namespace `s3`) | `versity/versitygw:v1.9.0` | S3-compatible server on port `9000`, access key `flux-s3`, secret key `flux-s3-secret` (the single root user, used by both Flux and the client); section 040 only, with no Gitea |
| `s3-client` (namespace `s3`) | `amazon/aws-cli:2.38.4` | Runs `aws s3` commands against `versitygw`; the reader uploads through it |
| `podinfo` (Deployment and Service, namespace `podinfo`) | `ghcr.io/stefanprodan/podinfo:6.15.0` | The demo application; its Helm chart comes from `https://stefanprodan.github.io/podinfo` in section 030 |
| `tester` (namespace `gitea`) | `nicolaka/netshoot:v0.13` | Client pod with `curl` and `jq`; graders call the Gitea API and the registry API from here. Only where Gitea runs (section 010, the section 020 playground and lab) |

### Environment facts the text must respect

- **One name per service that works everywhere.** `gitea.localtest.me` and
  `registry.localtest.me` are public DNS names that resolve to `127.0.0.1`.
  On the reader's machine a port-forward answers them
  (`kubectl -n gitea port-forward svc/gitea-http 3000:3000 2222:2222`,
  `kubectl -n registry port-forward svc/registry 5001:5001`). Inside the
  cluster, the bootstrap adds one CoreDNS `rewrite stop` block per name that
  sends it to the Service **and rewrites the answer name back** (Go programs,
  Flux included, ignore an answer whose name differs from the question).
  Copy the function `add_coredns_rewrites` from
  `sections/section-010/module-01/playground/bootstrap/prepare.sh`; never the
  one-line `rewrite name` form. The S3 server is only used from inside the
  cluster, so it keeps its Service name `s3.s3.svc.cluster.local:9000`.
- **Addresses:** Git over HTTP `http://gitea.localtest.me:3000/gitops/fleet.git`,
  Git over SSH `ssh://git@gitea.localtest.me:2222/gitops/fleet.git`, registry
  `oci://registry.localtest.me:5001/<name>`. Some home routers block DNS
  answers that point at `127.0.0.1`; then the reader adds
  `127.0.0.1 gitea.localtest.me registry.localtest.me` to `/etc/hosts`. Every
  page that uses these names from the reader's machine says so in one
  sentence.
- **Plain HTTP everywhere, lab-only.** The registry needs `insecure: true` on
  the `OCIRepository` and `--insecure-registry` on `flux push artifact` and
  `flux list artifacts`; the bucket needs `insecure: true`. Say on every such
  page that a real registry or object store uses HTTPS.
- **Reading an artifact.** The network policies from `flux install` block
  other namespaces from source-controller. To list the files in an artifact,
  pages run a short-lived pod in `flux-system`:
  `kubectl -n flux-system run artifact-reader --rm -i --restart=Never --image=nicolaka/netshoot:v0.13 -- sh -c "curl -s <URL> | tar -tzf -"`.
- **Section 030 runs no Gitea and no registry**, and needs outbound internet from the cluster: the podinfo Helm
  chart comes from `https://stefanprodan.github.io/podinfo` and
  `oci://ghcr.io/stefanprodan/charts`.
- **Flux facts (from the documentation, not yet seen on a run):**
  - `GitRepository` `spec.ref`: `branch`, `tag`, `semver`, `name`, `commit`;
    later fields take precedence; without `ref` it follows `master`.
    `timeout` defaults to `60s`. Default ignore rules exclude `.git/`, CI
    files, `.sops.yaml` and some archive and image extensions; `spec.ignore`
    replaces the defaults. SSH Secrets hold `identity` and `known_hosts`.
  - `OCIRepository`: `url` is `oci://host:port/repository` without a tag;
    `ref` has `tag`, `semver`, `semverFilter`, `digest` (later wins; default
    tag `latest`); `insecure` allows HTTP; revision `<tag>@sha256:<digest>`;
    `layerSelector` picks a layer by media type (`extract` or `copy`).
  - `HelmRepository`: `type` `default` or `oci` (the `oci` type is in
    maintenance mode and has no artifact or status; the docs recommend
    `OCIRepository` for OCI charts). The default type stores
    `index-<revision>.yaml`. `interval` defaults to `1m`.
  - `HelmChart`: `chart`, `version` (default `*`), `sourceRef`,
    `reconcileStrategy` (`ChartVersion` default, or `Revision`),
    `valuesFiles`; revision is the chart version.
  - `Bucket`: `provider` `generic` (default), `aws`, `gcp`, `azure`;
    `bucketName`, `endpoint`, `insecure`, `region`, `prefix`; generic Secret
    keys `accesskey` and `secretkey`. The revision is a `sha256` of the list
    of object keys and their ETags, so the same content gives the same
    revision.
  - source-controller keeps `--artifact-retention-records` (default `2`)
    artifacts and removes older ones after `--artifact-retention-ttl`
    (default `1m0s`).
- **Many environments start broken on purpose.** A lab seeds a fault in Git,
  in the registry, in the bucket or in a Flux object. The fault is the
  material. Never "fix" it in the bootstrap.
- **The proof is a source on the expected revision.** A fix is proven with
  `flux get sources <kind>` showing `Ready True` and the expected revision,
  plus the workload that the revision describes (the number of replicas
  differs between the versions a lab seeds, so the replica count shows which
  version was applied).

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections and modules tables, how to run things | `README.md` |
| Introduction (see "Every course starts with an Introduction") | `sections/intro/` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, closing page | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab: task, walkthrough, setup, grader | `.../labs/lab-01/` (`question.md`, `solution.md`, `prerequisites.md`, `bootstrap/`, `manifests/`, `solution/`, `testing/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`config.yaml`, `bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`, which is the only learner page) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

A lab folder holds:

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition; `metadata.docs` points at `question.md` and `solution.md` |
| `README.md` | Short intro for authors with `estimated_duration` front matter and the run, submit and destroy commands |
| `prerequisites.md` | What the learner needs before starting |
| `question.md` | The task. Starts with `# Question` and `Solve this question on: \`terminal\`` |
| `solution.md` | Step-by-step walkthrough |
| `bootstrap/01-install-git-and-flux.sh`, `02-seed-state.sh` | Gitea (plus the registry or the S3 server where the section needs them), the CoreDNS rewrites, the Flux CLI and controllers, then the starting state |
| `manifests/` | `lab-start.yaml` and any extra services, `repo/` (files seeded into `gitops/fleet`), and the starting Flux objects |
| `solution/apply.sh` | Reference end state, applied only by `astrona test` |
| `testing/wait-for-flux.sh` | Waits until Gitea and the Flux controllers answer before the reference solution runs |
| `validation/validate-*.sh` | Behavioural grading, one script per check |

Scripts that must reach Gitea or the registry from the machine (seed scripts
and reference solutions) start their own background port-forward and stop it
on exit; see `start_port_forward` in the section 010 lab solution.

### Lab metadata in `astrona.yaml`

`astrona.yaml` has a `training:` block (id `ATS095`, domain
`Source Controller & Repository Management`, weight `20`) and one entry per
section under `modules:` (`module-010` to `module-040`). Each section's
`content` lists, in order: the section `README.md`, then the module's landing
page, its parts, and right after the part a lab tests, a `Question` reading
followed by the `type: lab` entry; the summary comes last, then the section
capstone. Playgrounds are not listed.

Every `type: lab` entry carries the same fields, in the same order, as in
ATS016: `title`, `path`, `difficulty`, `estimated_duration`, `topic`,
`task_kind`, `tags`, `learning_goals`, `resources`.

- `topic`: exactly one of `git-sources`, `authentication`, `oci-sources`,
  `helm-sources`, `bucket-sources`, `artifacts`.
- `task_kind`: exactly one of `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8 ids, only from the tag list below. Add a new tag to the list
  first if nothing fits.
- `learning_goals`: 2 or 3 plain sentences, each starting with a verb.
- `resources`: 1 to 4 pages on `fluxcd.io`, each with a `name` and a `url`
  that loads. This is the **only** place outside links are allowed.

**Tag list** (lower case, hyphens, never synonyms):

- Git: `gitrepository`, `git-ref`, `semver`, `sourceignore`, `include`,
  `https-auth`, `ssh-auth`, `deploy-key`, `known-hosts`
- OCI: `ocirepository`, `flux-push-artifact`, `oci-registry`,
  `insecure-registry`, `digest`
- Helm: `helmrepository`, `helmchart`, `helmrelease`, `helm-index`,
  `helm-oci`
- Buckets and triggers: `bucket`, `s3`, `access-keys`, `reconcile-trigger`,
  `interval`
- Artifacts and tools: `artifact`, `artifact-revision`,
  `garbage-collection`, `kustomization`, `flux-get`, `flux-events`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-010/module-01/playground
astrona destroy ats-095-playground-010-01   # takes metadata.name from config.yaml, not the path

# Lab or capstone (graded against the live cluster)
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-095-lab-010-01

# Authors: run a local, uncommitted copy, and prove a lab passes with its reference solution
astrona run -c sections/section-010/module-01/playground
astrona test -c sections/section-010/module-01/labs/lab-01
```

Names: a playground is `ats-095-playground-<section>-<module>`, a module lab
is `ats-095-lab-<section>-<module>` and a capstone is
`ats-095-capstone-<section>`; keep those names. Lab bootstrap scripts do not
pin a kube context: astrona sets `KUBECONFIG` for the lab. Every lab must pass
`astrona validate` and `astrona test`.

Graders check **behaviour**, not just that an object exists: a `Ready`
condition on the expected revision, and the workload that revision describes.
Graders also reject the plausible but wrong fix (pinning a `commit` or a
`digest` to hide a range problem, keeping the password Secret next to the
SSH key, deleting and recreating a source, shortening an interval instead of
triggering a reconcile, applying the application with `kubectl`). A lab's
`question.md` and `solution.md` must match what its `validation/` scripts
actually check.

Test clusters on the maintainer's machine: one at a time. Section 020 adds a
registry and section 040 an S3 server to Gitea and the Flux controllers.

### Where to find trusted sources

Check facts here before writing them down. Prefer these over memory.

- **Source APIs:** [GitRepository](https://fluxcd.io/flux/components/source/gitrepositories/),
  [OCIRepository](https://fluxcd.io/flux/components/source/ocirepositories/),
  [HelmRepository](https://fluxcd.io/flux/components/source/helmrepositories/),
  [HelmChart](https://fluxcd.io/flux/components/source/helmcharts/),
  [Bucket](https://fluxcd.io/flux/components/source/buckets/),
  [source-controller options](https://fluxcd.io/flux/components/source/options/)
- **CLI:** [flux push artifact](https://fluxcd.io/flux/cmd/flux_push_artifact/),
  [flux list artifacts](https://fluxcd.io/flux/cmd/flux_list_artifacts/),
  [flux create secret git](https://fluxcd.io/flux/cmd/flux_create_secret_git/),
  [flux create source oci](https://fluxcd.io/flux/cmd/flux_create_source_oci/)
- **Guides:** [OCI artifacts cheatsheet](https://fluxcd.io/flux/cheatsheets/oci-artifacts/)

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository:
planning (`domain-plan`), creating the tree (`domain-scaffold`), building
modules (`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds
(`lab`), lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
