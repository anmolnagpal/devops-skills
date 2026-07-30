# bad-k8s-vertical-only-no-hpa

Two related findings that are not the same finding, which is why both are expected.

- `ARCH-HA-002` — `autoscaling.enabled: false` with a fixed `replicaCount: 2` on a
  request-serving service in prod. Load above what two pods handle has nowhere to go.
- `ARCH-SCAL-001` — the shape of the resources makes it vertical-only: 4 CPU and 16Gi
  requested per pod, 8 CPU limit. The response to more traffic here is a bigger pod,
  which has a ceiling and a restart cost that horizontal scaling does not.

The second is deliberately gated on size. Per exclusion 9, a 100m/128Mi pod with no
HPA is small and fixed rather than vertically scaled, and must not raise
`ARCH-SCAL-001`. This fixture is large on purpose so the two rules can be told apart:
a small no-HPA service should produce only `ARCH-HA-002`.

Must NOT fire: `ARCH-SPOF-002` (two replicas meets the staging/prod minimum),
`COST-K8S-001` (requests and limits both set), `COST-K8S-003` (memory limit equals
request), `ARCH-HA-003` (both probes present), `SEC-K8S-001` (full securityContext),
`SEC-K8S-006` (ClusterIP), `SEC-K8S-007` (token automount off), `CICD-DOCK-001` (tag
empty, set at deploy), `COST-TAG-001` (all three labels).
