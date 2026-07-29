# bad-k8s-memory-limit-below-request

The last uncovered rule in this catalog, and a single-line defect with an outsized
consequence: `requests.memory` is `2Gi` while `limits.memory` is `1Gi`.

Kubernetes rejects the pod spec outright, so this never even schedules. It reads as a
plausible pair of numbers, both units are correct, and the CPU request-to-limit ratio
above it is sensible, which is why it survives review.

`COST-K8S-001` must NOT fire: both requests and limits are present. The defect is
their relationship, not their absence, and reporting both would suggest adding
something that is already there.

Everything else is prod-clean so nothing else can fire: three replicas, tag set at
deploy, all three labels, both probes, full securityContext, ClusterIP, token
automount off.
