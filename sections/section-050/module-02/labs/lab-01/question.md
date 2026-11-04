# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** source-controller flags and resources

## Scenario

Your platform team added many sources to the cluster, and source-controller is slow: it reconciles one source at a time and the artifact folder grows. Someone already set `--concurrent=1` on the Deployment `source-controller` in `flux-system`. You tune it.

## Your task

Change the Deployment `source-controller` in the namespace `flux-system` so that its container:

1. Reconciles 8 sources at a time (`--concurrent=8`).
2. Keeps 4 artifact records per source (`--artifact-retention-records=4`) and deletes older artifacts after 5 minutes (`--artifact-retention-ttl=5m`).
3. Requests 256Mi of memory and is limited to 2Gi of memory.
4. Still stores artifacts in `/data` (`--storage-path=/data`).

Then wait until the new pod is available and check that `fleet` and `podinfo` are `Ready` again.

## Constraints

- Use the form `--flag=value` as a single argument.
- Each of the three flags appears exactly once. Do not leave the old `--concurrent=1` next to the new one.
- Do not delete the Deployment and do not change the CPU values.
- Do not remove the other arguments.

## Done when

- The args of source-controller hold exactly one `--concurrent=8`, one `--artifact-retention-records=4`, one `--artifact-retention-ttl=5m` and `--storage-path=/data`.
- The memory request is `256Mi` and the limit `2Gi`.
- The Deployment is rolled out and `fleet` and `podinfo` are `Ready`.
