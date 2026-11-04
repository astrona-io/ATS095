# Summary

A `GitRepository` fetches what its spec says and nothing else, so each field changes the content of the artifact or the trust placed in it.

## What you learned

`spec.verify` checks signatures before source-controller stores a revision. The mode `HEAD` checks the commit, `Tag` checks the tag object and `TagAndHEAD` checks both. The trusted public keys live in a Secret named in `verify.secretRef`, with the suffix `.asc` for PGP and `.sshpub` for SSH, and that Secret is different from the one with the Git credentials. The result is the condition `SourceVerifiedCondition`, `True` with the reason `Succeeded` or `False` with the reason `Failed`, and a failed check stops the revision from being stored.

Content from a second repository arrives through submodules or through `spec.include`. `recurseSubmodules` is off by default and reuses the credentials of the main repository, which is why deploy keys fail. `include` copies the artifact of another `GitRepository` to a `toPath`, so each repository keeps its own Secret and status, and a broken included repository gives the condition `IncludeUnavailable`.

`sparseCheckout` limits the checkout to listed directories, while `ignore` only removes files from the artifact. The status fields `observedSparseCheckout`, `observedInclude` and `observedRecurseSubmodules` show what built the current artifact. `ref.name` takes a full reference such as `refs/tags/v1.1.0` or `refs/pull/420/head`, and the order `branch`, `tag`, `semver`, `name`, `commit` decides which field wins. The key facts to remember are these:

- A failed verification means no artifact for that revision.
- `sparseCheckout` names directories, and a wrong name fails in the consumer.
- `name` overrides `branch`, and `commit` overrides everything.
- Some providers cannot fetch pull request references.

<!-- astrona:playground:destroy -->
