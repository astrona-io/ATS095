# Verify Commits, Include Repositories And Fetch Less — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-095-playground-010-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

> **Not yet run.** This playground was written from the Flux v2.9
> documentation and has not been started on a cluster yet.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-095-playground-010-03
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-095-playground-010-03`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Flux CLI and controllers, the module's services, CoreDNS rewrites and seed data |
| `manifests/lab-start.yaml` | Gitea and the tester pod |
| `manifests/repo/` | Files committed to `gitops/fleet`; `prepare.sh` adds the tags |
| `manifests/repo-platform/` | Files committed to `gitops/platform` |
| `manifests/flux-sync.yaml` | GitRepository `fleet` and Flux Kustomization `podinfo` |
| `docs/overview.md` | What the environment contains and ideas to try |
