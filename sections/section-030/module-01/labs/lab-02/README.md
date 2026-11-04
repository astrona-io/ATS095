---
estimated_duration: 20m
---

# Find Why A HelmChart Is Not Ready

- **ID:** LAB
- **Slug:** ats-095-lab-030-01-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespaces `flux-system`. Read `question.md` for the task; `solution.md` is the walkthrough.

> **Not yet run.** This lab was written from the Flux v2.9 documentation and
> has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-095-lab-030-01-02
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-095-lab-030-01-02`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Flux CLI and controllers, the lab services and CoreDNS rewrites, then the starting state |
| `manifests/` | `lab-start.yaml` (namespace podinfo), `helm-sources.yaml` (a working HelmRepository and a broken HelmChart) |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Waits for the lab services and the Flux controllers |
| `validation/` | Grading scripts, one per check |
