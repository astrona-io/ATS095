# Section 050: Operate source-controller

The earlier sections taught the source kinds. This section is about the controller that serves them. You look at what source-controller stores and where, size it for a larger cluster, find the cause of a failing source quickly, and keep one team's sources apart from another team's in a shared cluster.

**Topic covered:** Artifact storage, tuning and sizing, troubleshooting and multi-tenant access

## What you will learn

- Where source-controller keeps artifacts, how the artifact URL is built, and how to download one and check its digest by hand.
- What a restart and garbage collection do to stored artifacts, and which artifact is never deleted.
- Which flags and resources decide how much work source-controller can do: `--concurrent`, the retention flags, the cache flags, requests and limits.
- How to make a tuning change survive in a bootstrapped cluster, and what sharding with `--watch-label-selector` does.
- A fixed method for a failing source: overview, condition, events, log. What the common messages mean, and the difference between suspended, stalled and silent sources.
- How to fix a source without breaking the objects that use it, and how to prove the fix reached the cluster.
- Tenants, `--no-cross-namespace-refs`, impersonation with `serviceAccountName`, and what Flux does not restrict.

## The learning path

Each module has a landing page, several parts, a graded lab right after the part it tests, and a summary. The landing page also starts the module's playground.

### 1. How source-controller Stores And Serves Artifacts

1. Where Artifacts Live
2. Reading An Artifact By Hand, followed by the lab **Prove What source-controller Stored**
3. Retention, Restarts And The Latest Artifact
4. Who Reads The Artifact
5. Summary

### 2. Tune And Size source-controller

1. What Makes source-controller Busy
2. Flags For Concurrency, Retention And Caches
3. Resources, Limits And Restarts, followed by the lab **Tune source-controller**
4. Making Changes Stick And Sharding
5. Summary

### 3. Troubleshoot Failing Sources

1. A Method: Read, Narrow, Fix
2. What The Messages Mean
3. Suspended, Stalled And Silent Sources, followed by the lab **Fix Failing Sources**
4. Fixing Safely And Proving It
5. Summary

### 4. Control Access To Sources In A Multi-Tenant Cluster

1. Tenants And Namespaces
2. Cross-Namespace References And The Flag
3. Impersonation With serviceAccountName, followed by the lab **Tenant Isolation**
4. What Flux Does Not Restrict
5. Summary

## Section capstone: Operate source-controller

The capstone is one graded scenario with several independent faults: source-controller runs with too little concurrency, one source points at a branch that does not exist, another is suspended, and a tenant's Kustomization is blocked by a cross-namespace reference. You fix each object in place. Work it after the module labs.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-050/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-050/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-095-capstone-050
```
