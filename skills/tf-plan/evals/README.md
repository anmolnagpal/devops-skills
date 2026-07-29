# Terraform plan skill evals

Eval-driven development for the `/clouddrove:tf-plan` review mode. Each case is an **input
fixture** plus the **exact rule IDs** the skill must surface on it. This makes
"the skill catches X" provable and regression-gated, not claimed.

This is the reference eval layout for every review skill in this repo — copy it.

## Layout

```
evals/
  README.md            ← this file
  cases/
    <case-name>/
      <input file>     ← plan fixture (tfplan.json, CI workflow)
      expected.txt     ← one rule ID per line the skill MUST report (empty = clean)
  validate.sh          ← static consistency check (CI-runnable, no model needed)
```

## Two layers of checking

1. **Static validation (`validate.sh`, CI-runnable now).** Asserts every ID in
   every `expected.txt` exists in the skill's Rule Catalog, and that the `clean/`
   case expects nothing. Catches typos, renamed/deleted rules, and drift between
   the catalog and the evals. No model invocation.

2. **Model grading (manual / harness).** Run the `/clouddrove:tf-plan review` skill against
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
bash skills/tf-plan/evals/validate.sh
```

Exit non-zero on any unknown rule ID or a non-empty `expected.txt` in a `clean-*`
case. Runs in CI (`scripts/check-evals.sh`) alongside `scripts/generate.sh --check`.

## Run behavioral (Tier-2) validation

```bash
EVALS=1 bash scripts/run-behavioral-evals.sh tf-plan
```

Actually invokes `/clouddrove:tf-plan review` against each fixture via `claude -p` and
diffs live output against `expected.txt` — catches a real regression (skill stops
detecting a violation), not just doc drift. Opt-in: spends API tokens, not wired
into the free CI gates. Run manually or on a nightly schedule.

`clean-tfplan-additive` carries the precision load. Its fixture is deliberately
full of things that look like findings and are not: a data-bearing log group in a
`no-op` whose `tags_all` differs from `tags` only by a provider-injected default,
an IAM policy that belongs to a different skill's catalog, and an ECS update that
changes a task definition in place. Any finding on this case is a false positive.

The verdict line is part of the contract, not decoration. This skill's output ends
in `SAFE TO APPLY`, `APPLY WITH CARE`, or `DO NOT APPLY`, and a run that reports
the right rule IDs while leaving the reader to infer the conclusion should be
treated as a failure during behavioral grading.

The pair worth protecting is `bad-tfplan-unbound-apply` against itself: one
resource has a readable `password` with `after_sensitive: false` and must fire
`TF-PLAN-002`, while an SSM SecureString in the same plan has
`after_sensitive: true` and must stay silent. A skill that greps for
secret-shaped strings fails that pair; one that reads the sensitivity markers
passes it.

## Adding a case

1. `mkdir cases/<descriptive-name>/`
2. Drop a fixture: a `tfplan.json` (from `terraform show -json`), optionally a CI
   workflow when the case is about the apply path.
3. Write `expected.txt` — one rule ID per line, the IDs the skill must report.
   Empty file for a clean plan.
4. `bash validate.sh` → green.
