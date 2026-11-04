# Summary

A failing source explains itself, if you read it in order.

## What you learned

Start with `flux get sources all -A`, then read the conditions and `observedGeneration`, then `flux events --for`, then `flux logs`. Match the message to a cause: authentication, a missing reference, a wrong URL, a private CA, a wrong chart or bucket name. Some sources show no error: a suspended source keeps the status of its last run and is skipped, a stalled source waits for a spec change, and a ready source can leave the cluster unchanged when the consumer is stuck. Fix by changing one value at a time under the same name, ask for a reconcile with `--with-source`, and prove the result by comparing `status.artifact.revision` with `status.lastAppliedRevision` and by running `flux trace`. The key facts to remember are these:

- Order: overview, condition, events, log.
- Check `observedGeneration` before you trust a message.
- A suspended source is silent, not healthy.
- Done means the consumer applied the new revision.

<!-- astrona:playground:destroy -->
