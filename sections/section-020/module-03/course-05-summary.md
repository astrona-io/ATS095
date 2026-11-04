# Summary

The `flux` artifact commands cover the half of delivery that happens outside the cluster.

## What you learned

`flux build artifact` writes the archive to a local file, `flux push artifact` uploads it with `--source`, `--revision` and optional `--annotations`, and `--output json` returns the digest for the next step. The default ignore list removes `.git/`, images and archives. `flux pull artifact` extracts a release, by tag or by `@sha256:` digest. `flux diff artifact` compares a release with a folder and exits with a non-zero code when they differ. `flux list artifacts` shows tags with their digests and takes `--filter-semver` and `--filter-regex`.

A promotion adds a tag to an existing manifest, or passes the digest on. A tag moves; a digest does not. `ref.digest` of an `OCIRepository` wins over tag and semver. A signature belongs to a digest, so a pipeline signs the address from `--output json`. The key facts to remember are these:

- Build once, then promote the same digest.
- `flux tag artifact` has no `--insecure-registry`; the registry API can add a tag on any registry.
- A non-zero exit of `flux diff artifact` means the content differs.
- Pin production to a digest, and let staging follow a tag.

<!-- astrona:playground:destroy -->
