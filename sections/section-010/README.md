# Section 010: GitRepository In Depth

A `GitRepository` looks simple: a URL, a branch and an interval. Behind those fields, source-controller makes three decisions every time it runs. It decides which commit to fetch, which files of that commit go into the artifact, and how to prove to the Git server that it may read the repository. When one of those decisions is wrong, the cluster quietly runs the wrong version, or nothing at all.

This section makes each decision explicit. You choose the commit with a branch, a tag, a semver range, a full reference or a commit. You shape the artifact with ignore rules and with includes from a second repository. And you give Flux read access, first with a username and password over HTTP, then with a read-only SSH deploy key.

**Topic covered:** Git sources and authentication

## What you will learn

- The five fields of `spec.ref` (`branch`, `tag`, `semver`, `name`, `commit`), which one wins, and what each does to the revision.
- How a semver range picks a release, and why an open range is a risk.
- What the default ignore rules leave out of an artifact, and how `.sourceignore` and `spec.ignore` change that.
- How `spec.include` copies files from a second `GitRepository` into the artifact.
- The keys of a Secret for HTTPS basic authentication and for SSH.
- How to create an SSH key pair for Flux, register it as a read-only deploy key, and move a `GitRepository` from a password to SSH.

## The learning path

The module has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page also starts the module's playground, a cluster where you can explore freely.

### 1. Control What source-controller Fetches From Git

The playground holds Gitea, an in-cluster Git server, with the repository `gitops/fleet`. The repository has two release tags, a `docs` folder, and a second repository `gitops/platform`. Flux already deploys `podinfo` from the branch `main` over HTTP.

1. Choosing A Git Reference
2. Shaping The Artifact With ignore And include
3. HTTPS Credentials And SSH Deploy Keys, followed by the lab **Move The GitRepository To An SSH Deploy Key**
4. Summary

### 2. Secure Git Connections And Git Providers

The playground is the same Gitea server and `gitops/fleet` repository as the first module. It uses no TLS and no proxy, so you create the Secrets for those and read back their keys, and you work the SSH host key checks for real.

1. TLS Certificates For HTTPS Git Servers
2. HTTP Proxies And Timeouts
3. Tokens, Bearer Authentication And Git Providers
4. SSH Host Keys And known_hosts, followed by the lab **Repair A Git SSH Connection**
5. Summary

What you will also learn in this module:

- The Secret keys `ca.crt`, `tls.crt` and `tls.key` for private CAs and mutual TLS.
- How `proxySecretRef` and `spec.timeout` shape the connection of one source.
- Which Secret keys and `spec.provider` value each sign-in method needs: basic, bearer token, GitHub App, cloud identity.
- How to write a `known_hosts` entry for a port other than 22 and how to repair a host key mismatch.

### 3. Verify Commits, Include Repositories And Fetch Less

The playground is the same Gitea server with `gitops/fleet` and `gitops/platform`. You turn on signature verification and read why it fails for unsigned commits, include `gitops/platform` in the artifact, shrink the artifact with a sparse checkout, and follow a full reference with `ref.name`.

1. Verify Commit And Tag Signatures
2. Submodules And Included Repositories
3. Sparse Checkout And Smaller Artifacts
4. Exact Git References With ref.name, followed by the lab **Fetch The Right Directories From The Right Reference**
5. Summary

What you will also learn in this module:

- The modes `HEAD`, `Tag` and `TagAndHEAD` of `spec.verify`, the Secret keys with the suffixes `.asc` and `.sshpub`, and the condition `SourceVerifiedCondition`.
- When to use `recurseSubmodules` and when `spec.include` is the better fit.
- How `sparseCheckout` limits the artifact and how `observedSparseCheckout` shows what built it.
- Which `ref` field wins, and how to follow a tag or a pull request with `ref.name`.

## Section capstone: Pin A Release Line And Trim The Artifact

The capstone is one graded scenario that combines the reference and the artifact parts of the module. The `GitRepository` `fleet` follows every release from `1.0.0` upwards, and the newest release, `v2.0.0`, uses an image that does not exist. You restrict the source to the 1.x releases and keep the documentation out of the artifact, without changing anything in Git. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-095-capstone-010
```
