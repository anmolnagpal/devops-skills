# bad-deploy-not-ready

The first eval suite this skill has ever had. `deploy` aggregates rather than
re-derives, so a fixture needs real artifacts for it to read: a Helm values file and a
workflow, in the shape a repo actually has them.

Six findings, each owned by a different concern:

- `ARCH-SPOF-002` — `replicaCount: 1` on a first prod release. One pod, no headroom
  during a rollout.
- `ARCH-HA-003` — no `readinessProbe` or `livenessProbe`, so the orchestrator cannot
  gate traffic or restart a wedged pod.
- `CICD-DOCK-001` — `tag: latest`. Two deploys of "the same version" can ship
  different bytes.
- `SEC-SEC-001` — a Stripe key as a literal `env[].value` rather than a `secretKeyRef`.
- `CICD-FLOW-002` — the deploy job has no `environment:` and no manual gate, so a push
  to main reaches production unreviewed.
- `ARCH-DR-002` — no RTO, RPO, or rollback procedure anywhere in the fixture, and this
  is a first production release.

The gate's verdict must be `FAILED` (or `INCOMPLETE`, see below), never `READY`.

**On `INCOMPLETE`:** this skill's contract is that it reports which artifact skills
actually ran, and returns `INCOMPLETE` rather than claiming `READY` when an artifact
type is present but unchecked. A run that reports the six IDs above has effectively
consulted the k8s and github-actions views; a run that reports nothing and says
`INCOMPLETE` is also correct behavior and should be read as the gate working, not
failing. What must never happen is `READY`, or a finding this skill invented without
the owning skill's basis, which exclusion 1 forbids.

`OBS-MON-001`, `OBS-MON-002`, and `OBS-SLO-001` are deliberately **not** expected.
There is no monitoring configuration in this fixture at all, and per the observability
skill's own scoping an absence claim needs the place it would live to be visible. A
two-file fixture is not that.
