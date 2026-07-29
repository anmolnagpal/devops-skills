# bad-k8s-rbac-cluster-admin

Two independent routes to cluster takeover, both `SEC-K8S-003`: a `ClusterRole`
with wildcard apiGroups, resources, and verbs, and a `ClusterRoleBinding` whose
`roleRef` is `cluster-admin`. Either alone is BLOCKING.

This case ships a complete chart (`Chart.yaml` plus `templates/`) specifically so
`SEC-K8S-004` is assessable: there is no `NetworkPolicy` template and no mesh or
CNI policy anywhere in the fixture, so the ADVISORY fires. That is the difference
between this case and `bad-k8s-host-boundary`, which is a bare values file and
must stay silent on `SEC-K8S-004`.

Nothing else may fire: image tag pinned, replicas 3, both probes, requests and
limits set, memory limit equal to request, all three labels, full securityContext.
`SEC-K8S-007` must NOT fire either: the workload holds a ServiceAccount it
genuinely uses to call the API server, which is exclusion 9.
