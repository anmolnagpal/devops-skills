# clean-k8s-daemonset-hostpath

Exercises false-positive exclusion 5. A DaemonSet log shipper mounting `/var/log`
and the container log directory is the documented exception to `SEC-K8S-002`:
both mounts are `readOnly: true` and neither is a sensitive path like `/`, `/etc`,
or `docker.sock`. Nothing may fire.

`runAsUser: 0` is present and must NOT produce `SEC-K8S-001`: reading node logs
requires root, `allowPrivilegeEscalation: false` and `readOnlyRootFilesystem: true`
are set, and this is a node agent rather than an application container.

No `replicaCount` is expected of a DaemonSet, so `ARCH-SPOF-002` stays silent for
the same reason it does on the CronJob case (exclusion 2 covers run-to-completion
and node-scoped workloads).

`SEC-K8S-007` must NOT fire: fluent-bit uses in-cluster config to enrich records
with pod metadata, so it needs its token (exclusion 9).
