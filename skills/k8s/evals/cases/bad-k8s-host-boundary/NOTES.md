# bad-k8s-host-boundary

An ordinary Deployment (not a node agent), so exclusion 5 does not apply. Four
separate host-boundary breaks, all folding into one `SEC-K8S-002` finding per the
consolidate-repeats rule: `hostNetwork`, `hostPID`, `privileged: true`, and a
writable `docker.sock` `hostPath`.

Deliberately clean on everything else so nothing but `SEC-K8S-002` can fire:
replicas 3, both probes, requests and limits set, memory limit equal to request,
all three labels, tag empty (set at deploy), token automount off, `ClusterIP`.

`SEC-K8S-001` must NOT fire: `runAsNonRoot`, `allowPrivilegeEscalation: false`,
and `readOnlyRootFilesystem` are all present. `privileged: true` sitting in the
same block contradicts them in practice, which is exactly why it is a separate
BLOCKING rule rather than a securityContext completeness nit.

`SEC-K8S-004` must NOT fire: no `templates/` here, so per exclusion 7 there is no
evidence about whether a NetworkPolicy exists elsewhere.
