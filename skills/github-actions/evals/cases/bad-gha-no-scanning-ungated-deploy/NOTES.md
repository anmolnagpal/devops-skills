# bad-gha-no-scanning-ungated-deploy

Three rules that had no skill behind them, on a workflow that looks carefully built:
SHA-pinned actions with version comments, an explicit `permissions` baseline, OIDC
instead of static keys, a concurrency group, timeouts on every job, `cache: npm`, and
a production environment on both deploying jobs.

- `CICD-FLOW-001` — `deploy` declares `needs: [image]` and **not** `test`. The test
  job exists, runs, and gates nothing: a failing test does not stop the deploy,
  because `image` does not depend on `test` either. This is the finding a reader
  skims past, since a `needs:` is present and a test job is present, just not
  connected.
- `CICD-SCAN-002` — no `dependency-review-action`, no `.github/dependabot.yml` in the
  tree, and no `npm audit` step. `npm ci` installs dependencies without ever checking
  them.
- `CICD-SCAN-003` — the `image` job builds and pushes to ECR with no scan between the
  two. No Trivy, no Grype, no `docker scout`, and no ECR scan-on-push configuration
  visible.

Must NOT fire: `CICD-PIN-001` (all four actions SHA-pinned), `CICD-PERM-001`/`002`
(explicit `contents: read` plus the `id-token: write` OIDC needs),
`SEC-IAM-002` (OIDC role assumption, no static keys), `CICD-OPS-001` (concurrency
group), `CICD-OPS-002` (timeouts on all three jobs), `CICD-OPS-003` (`cache: npm`),
`CICD-FLOW-002` (both deploying jobs declare `environment: production`),
`CICD-SEC-001`/`003` (no hardcoded secrets, no `github.event.*` interpolation).

`CICD-SCAN-001` and `CICD-SCAN-002` overlap and both concern absent scanning. Only
`CICD-SCAN-002` is expected here: `001` is the broader "no SAST/DAST on an active
repo", and reporting both on one gap would double-count. If a run reports `001` too,
that is over-reporting rather than a second defect.
