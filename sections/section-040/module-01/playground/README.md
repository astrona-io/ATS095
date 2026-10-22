# Sync From A Bucket And Control When Flux Fetches — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-095-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

> **Not yet run.** This playground was written from the Flux v2.9
> documentation and has not been started on a cluster yet.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-095-playground-040-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-095-playground-040-01`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Flux CLI and controllers, the module's services, CoreDNS rewrites and seed data |
| `manifests/lab-start.yaml` | versitygw and the `s3-client` pod (namespace `s3`) |
| `manifests/bucket/` | Files uploaded to the bucket `podinfo` |
| `docs/overview.md` | What the environment contains and ideas to try |
