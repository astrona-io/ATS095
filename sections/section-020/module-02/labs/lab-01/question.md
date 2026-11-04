# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** OCI registry authentication

## Scenario

The registry at `registry.localtest.me:5001` now requires a sign-in. The user is `flux` and the password is `registry-password`. The `OCIRepository` `podinfo` in `flux-system` should deliver release `1.1.0` of `podinfo-manifests`, but it does not fetch. A teammate also created a Secret `regcred` in `flux-system` earlier and said it was ready.

Start by reading the state:

```sh
flux get sources oci
flux events --for OCIRepository/podinfo
kubectl -n flux-system get secret regcred -o jsonpath='{.type}{"\n"}'
```

## Your task

1. Find from the events of `podinfo` why it cannot fetch. There is more than one cause, and the second appears only after the first is fixed.
2. Make the `OCIRepository` use the Secret `regcred`, and make the Secret hold the right credentials.
3. Confirm that the Flux `Kustomization` `podinfo` applies the revision of the `OCIRepository`.

## Constraints

- Keep the tag `1.1.0` and the name `regcred`.
- Do not turn off the authentication of the registry, and do not change the registry.
- Do not put the password in the `OCIRepository`.

## Success criteria

- `podinfo` is Ready and its revision starts with `1.1.0@sha256:`.
- `regcred` is a `kubernetes.io/dockerconfigjson` Secret for `registry.localtest.me:5001`.
- The Flux `Kustomization` `podinfo` is Ready and the Deployment runs 3 ready replicas.
