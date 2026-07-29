# clean-incident-ready

Nothing may fire. Each rule stops at its bound:

- `REPO-DOC-002` — the one paging alert has a runbook, and the runbook is for this
  service.
- `OBS-MON-002` — `ReportGenJobFailing` carries a `runbook_url` that resolves to a
  real anchor in a file present in the fixture. `ReportGenSlowBatch` has no
  runbook link and must NOT be reported: it is `severity: ticket`, exclusion 4.
- `ARCH-DR-002` — suppressed with a reason that is also a valid exclusion 3 on its
  own merits, and it points at where the objectives actually live. This doubles as
  proof the `incident-skill:ignore` convention is honored and that a suppression
  carrying a reason does not raise `META-SUP-001`.
- `OBS-DASH-001` — a dashboard URL and a named log group with a named saved query.
- `OBS-SLO-001` — internal batch tooling with no external consumer, which is
  exclusion 7 of the observability skill's set and the same judgment here.

Every check in the runbook is a runnable command with an expected value and a
branch. That is the standard the RUNBOOK mode is asked to produce, so this fixture
is also the reference output: if a generated runbook is thinner than this one, the
generator has regressed.

The "What this runbook does not cover" section is deliberate. An on-call reading a
document needs to know where its coverage stops, and its presence must not be read
as an admission of a gap.
