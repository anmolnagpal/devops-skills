# bad-incident-no-runbook

Two documents, four findings, and the fixture is chosen so that counting files
gives the wrong answer: a runbook exists, so "do we have runbooks" is technically
yes.

- `REPO-DOC-002` — `checkout-api` has two paging alerts and no runbook anywhere.
  The finding must name those two alerts. The existing `payments-api.md` is for a
  different service and does not cover it, and there is no external location named
  in the fixture, so exclusion 2 does not apply.
- `OBS-MON-002` — neither paging alert carries a `runbook_url` annotation. The
  page arrives with a summary line and nothing else.
- `ARCH-DR-002` — `payments-api.md` states RTO 15m and RPO 5m with no record of a
  restore ever being tested. Numbers in a document. The service is stateful
  (Aurora, Redis), so exclusion 3 does not apply.
- `OBS-DASH-001` — "Check the dashboard if something looks wrong. Logs are in
  CloudWatch." No dashboard named, no link, no query. Exclusion 5 does not apply
  because there is no specific query either.

`CheckoutApiCacheMissRateElevated` must NOT contribute to `OBS-MON-002`: its label
is `severity: ticket`, not `page`, which is exclusion 4. A skill that flags every
alert without a runbook link over-reports by a third on this fixture alone.

The `payments-api.md` runbook must also NOT be reported under `REPO-DOC-002`. It is
a bad runbook, not a missing one, and its badness is already captured by the two
advisory findings. Reporting it twice under different rules would double-count.
