# bad-gha-selfhosted-nocache-noscan

Repo-shaped, because three of the six findings only exist across files:
`CICD-OPS-005` needs two workflows to compare, and `CICD-SCAN-001` is the absence of
any scanning workflow anywhere.

- `CICD-SEC-004` — `runs-on: [self-hosted, ...]` on a public repository with
  `on: pull_request` unqualified, so a fork PR executes attacker-authored code on
  a runner inside the network. The most serious finding here by a distance.
- `CICD-PERM-002` — neither workflow declares a `permissions` block, so both inherit
  the repository default token scope. ADVISORY, and distinct from `CICD-PERM-001`:
  nothing is explicitly over-granted, there is just no declared baseline.
- `CICD-OPS-003` — `actions/setup-node` is used without `cache: npm`, and `npm ci`
  runs in three jobs with no `actions/cache` anywhere. Known tool installs, no
  caching.
- `CICD-OPS-004` — the `test` job has a 2x2 matrix of independent Node and OS
  combinations and no `fail-fast: false`, so one failing combination cancels the
  other three and hides whether they would have passed.
- `CICD-OPS-005` — `test`, `lint`, and `build` repeat the same checkout, setup-node,
  and `npm ci` preamble three times across two files. Extract to `workflow_call`.
- `CICD-SCAN-001` — no CodeQL workflow, no dependency review, and no
  `.github/dependabot.yml` in the tree. Active repo, no scanning.

Must NOT fire: `CICD-PIN-001` (both actions are 40-char SHA pins with version
comments), `CICD-OPS-001` (both workflows declare a concurrency group),
`CICD-OPS-002` (every job sets `timeout-minutes`), `CICD-SEC-003` (no
`github.event.*` interpolation in any `run:`), `CICD-SEC-001` (no secrets at all),
`SEC-IAM-002` (no cloud auth in these workflows), `CICD-FLOW-002` (no production
deploy job here).

`build.yml` running on `ubuntu-latest` is deliberate: it must not attract
`CICD-SEC-004`, which is about self-hosted runners specifically.
