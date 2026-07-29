# Incident skill evals

Eval-driven development for the `/clouddrove:incident` review mode. Each case is an **input
fixture** plus the **exact rule IDs** the skill must surface on it. This makes
"the skill catches X" provable and regression-gated, not claimed.

This is the reference eval layout for every review skill in this repo — copy it.

## Layout

```
evals/
  README.md            ← this file
  cases/
    <case-name>/
      <input file>     ← runbook + alert-rule fixture
      expected.txt     ← one rule ID per line the skill MUST report (empty = clean)
  validate.sh          ← static consistency check (CI-runnable, no model needed)
```

## Two layers of checking

1. **Static validation (`validate.sh`, CI-runnable now).** Asserts every ID in
   every `expected.txt` exists in the skill's Rule Catalog, and that the `clean/`
   case expects nothing. Catches typos, renamed/deleted rules, and drift between
   the catalog and the evals. No model invocation.

2. **Model grading (manual / harness).** Run the `/clouddrove:incident review` skill against
   each `cases/<name>/` input and compare reported rule IDs to `expected.txt`:
   - **Recall (the pass/fail gate):** every ID in `expected.txt` MUST be reported.
     A missing one = false negative = case fails. `expected.txt` is the
     must-catch contract, not an exhaustive list.
   - **Precision (tracked, not gated):** extra *defensible* findings (e.g. also
     flagging a heavy base) don't fail a case; a clearly *wrong* finding does.
   - **Clean cases are exact:** a `clean-*` case fails on ANY reported finding.

   `pass@k` = fraction of runs meeting the recall gate. `scripts/run-behavioral-evals.sh`
   (below) is that harness — the fixtures + expected files are the contract it consumes.

## Run static validation

```bash
bash skills/incident/evals/validate.sh
```

Exit non-zero on any unknown rule ID or a non-empty `expected.txt` in a `clean-*`
case. Runs in CI (`scripts/check-evals.sh`) alongside `scripts/generate.sh --check`.

## Run behavioral (Tier-2) validation

```bash
EVALS=1 bash scripts/run-behavioral-evals.sh incident
```

Actually invokes `/clouddrove:incident review` against each fixture via `claude -p` and
diffs live output against `expected.txt` — catches a real regression (skill stops
detecting a violation), not just doc drift. Opt-in: spends API tokens, not wired
into the free CI gates. Run manually or on a nightly schedule.

Both cases turn on the same distinction, from opposite directions: a paging alert
without a runbook is a finding, and a ticket-tier alert without one is not.
`bad-incident-no-runbook` carries three alerts of which only two page, and
`clean-incident-ready` carries two of which only one pages. A skill that flags
every alert missing a `runbook_url` over-reports by a third on the first fixture
and fails the second outright.

`bad-incident-no-runbook` also exists to separate a **missing** runbook from a
**bad** one. It ships a real runbook for a different service that explains
architecture and links nothing. That document must produce the two advisory
findings about its content and must not also be counted as a missing runbook,
because double-counting one document under two rules is how a readiness audit
inflates.

`clean-incident-ready` doubles as the reference output for RUNBOOK mode. Every
check in it is a runnable command with an expected value and a branch. If a
generated runbook is thinner than that fixture, the generator has regressed even
though no eval turns red.

## Adding a case

1. `mkdir cases/<descriptive-name>/`
2. Drop a fixture: a runbook under `docs/runbooks/`, plus the alert rules whose
   coverage it is meant to prove.
3. Write `expected.txt` — one rule ID per line, the IDs the skill must report.
   Empty file for a clean fixture.
4. `bash validate.sh` → green.
