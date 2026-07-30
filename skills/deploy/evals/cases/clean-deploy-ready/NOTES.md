# clean-deploy-ready

Nothing may fire, and the verdict must be `READY`. The counterpart to
`bad-deploy-not-ready`, artifact for artifact, so the pair isolates what the gate keys
on.

Each of the six findings from the bad case is answered here:

- `ARCH-SPOF-002` — three replicas, with an HPA from 3 to 12
- `ARCH-HA-003` — both probes present with explicit timings
- `CICD-DOCK-001` — `tag: ""`, set at deploy from `github.sha`
- `SEC-SEC-001` — secrets via `envFrom.secretRef`, nothing inline
- `CICD-FLOW-002` — `environment: production` plus `needs: [test]`, so a failing test
  stops the deploy
- `ARCH-DR-002` — RTO, RPO, a rollback command, and a dated restore drill in the
  runbook

`ARCH-DR-001` must also stay silent: the runbook names a restore procedure and a
tested drill rather than asserting recovery with nothing behind it.

The gate is allowed to say `INCOMPLETE` here if it declines to consult an artifact
skill, and that is not a failure of this case. What must never happen is a finding: a
clean case that reports anything means the gate is inventing findings the owning skill
would not make, which exclusion 1 exists to prevent.
