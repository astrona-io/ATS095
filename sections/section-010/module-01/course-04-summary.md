# Summary

A `GitRepository` makes three decisions for source-controller: which commit to fetch, which files of it to pack, and how to sign in to the Git server. Each one is a few lines of YAML, and each one shows up in a place you can check.

## What you learned

The commit comes from `spec.ref`. A `branch` follows the newest commit, a `tag` stays on one commit, a `semver` range follows the highest matching release tag, a `name` takes a full Git reference, and a `commit` pins one commit. When several are set, the later one in that order wins, and without any `ref` source-controller follows `master`. The revision in `flux get sources git` names both the reference and the commit, such as `v1.1.0@sha1:` followed by the hash, so it always tells you what the cluster got. A semver range with an upper bound, such as `>=1.0.0 <2.0.0`, turns a Git tag into a release and keeps the next major version out until a person allows it.

The files come from the commit, minus the ignore rules. The default rules leave out Git files, images, archives and CI configuration. A `.sourceignore` file in the repository adds rules but only affects the commits that contain it, while `spec.ignore` replaces the defaults and applies at the next fetch. `spec.include` copies the artifact of a second `GitRepository` into a folder of this one. The artifact can only be read from inside `flux-system`, because the Flux network policies block other namespaces.

The credentials come from the Secret in `spec.secretRef`. Basic authentication uses the keys `username` and `password` and belongs on HTTPS. SSH uses `identity`, `identity.pub` and `known_hosts`. `flux create secret git` with an `ssh://` address generates the key pair, reads the server's host key and stores all three. Registered as a read-only deploy key, the public key reaches one repository and cannot push. The key facts to remember are these:

- Later `ref` fields win: `commit` over `name` over `semver` over `tag` over `branch`.
- An ignore rule changes the artifact, not the revision.
- An SSH Secret needs `known_hosts`, and the URL and the Secret change together.
- Delete the old password Secret after a move to SSH.

<!-- astrona:playground:destroy -->
