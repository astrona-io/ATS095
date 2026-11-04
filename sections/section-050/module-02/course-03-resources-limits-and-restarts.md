# Resources, Limits And Restarts

The flags decide how much work happens. The container resources decide whether the pod survives it.

## Read the resources

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system get deployment source-controller \
  -o jsonpath='{.spec.template.spec.containers[0].resources}' | jq
```

The standard installation sets a CPU request, a memory request and a memory limit. The scheduler uses the **requests** to place the pod. The kubelet enforces the **limit**: a container that goes over its memory limit is killed.

## OOMKilled

When the kernel kills a container for memory, Kubernetes records it:

```sh
kubectl -n flux-system get pod -l app=source-controller \
  -o jsonpath='{.items[0].status.containerStatuses[0].lastState}{"\n"}'
```

A `terminated` state with the reason `OOMKilled` and a growing restart count means the limit is too low for the work. Typical causes are a very large Git repository, a `HelmRepository` with a huge index, or a `--concurrent` that is high compared with the limit. The fix is a higher limit, a lower concurrency, or smaller sources (see the sparse checkout and the ignore rules from earlier sections).

## Memory is the number to protect

CPU over the limit only slows the controller down. Memory over the limit kills it, and a kill also empties the storage and costs a full round of fetches. A common choice is a request close to normal use and a limit with room for a burst, for example a request of `256Mi` and a limit of `2Gi` for a busy installation. Measure with your own metrics (for example from the Prometheus endpoint on port 8080 of the pod) before you copy numbers.

## What a restart costs

Changing the pod template (args, resources, image) rolls the Deployment. The new pod has an empty `emptyDir`, so it fetches every source once, in parallel up to `--concurrent`. During that window the consumers keep applying their last revision from their own state, and new commits wait. On a large cluster, roll source-controller at a calm time and watch `flux get sources all -A` until everything is `Ready` again.

## A persistent volume

If the fetch burst after a restart is too heavy, replace the `emptyDir` with a persistent volume at `/data`. Artifacts then survive a restart. The price is storage you manage and a Deployment strategy of `Recreate`, because a volume that can be mounted once cannot be shared by two pods during a rolling update.

## Your mission: Tune source-controller

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-095-playground-050-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS095.git -c sections/section-050/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-050/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-095-lab-050-02
astrona start ats-095-playground-050-02
```
