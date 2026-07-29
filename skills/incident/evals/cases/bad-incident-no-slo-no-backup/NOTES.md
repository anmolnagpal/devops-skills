# bad-incident-no-slo-no-backup

The last two uncovered rules in this catalog, on a runbook that is genuinely good.
Everything the previous cases test is correct here: the paging alert has a resolving
`runbook_url`, mitigation comes first, every check is a runnable command with an
expected value and a branch, the dashboard and log group are named, escalation is a
named schedule, and the recovery objectives are stated *and* dated with a real drill.

- `ARCH-DR-001` — the runbook's restore procedure says "restore the Aurora cluster
  from its most recent automated snapshot", and `orders-db.tf` sets no
  `backup_retention_period`, defines no AWS Backup plan, and has
  `skip_final_snapshot = true`. The documented recovery depends on a snapshot that
  nothing creates. This is the finding that only appears when the runbook and the
  infrastructure are read together, which is why the fixture ships both.
- `OBS-SLO-001` — no SLI, no target, no error budget anywhere. The alert threshold is
  a bare 5%, so during an incident the question "is this bad enough to page" has no
  agreed answer and gets argued from scratch. Exclusion 7 does not apply: orders is
  user-facing commerce, not internal tooling.

`ARCH-DR-002` must NOT fire, and this is the pair that makes `ARCH-DR-001` meaningful.
RTO and RPO are both stated and there is a dated restore drill from 2026-05-12, so the
objectives rule is satisfied. The defect is that the objectives are unachievable
because the backups behind them do not exist. A skill that collapses these two into
one finding cannot express that difference.

`REPO-DOC-002` must NOT fire (a runbook exists for the service with the paging
alert), nor `OBS-MON-002` (the alert carries a resolving runbook link), nor
`OBS-DASH-001` (dashboard and logs are both named).
