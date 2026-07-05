# Docker skill evals

Eval-driven development for the `/docker` review mode. Each case is an **input
fixture** plus the **exact rule IDs** the skill must surface on it. This makes
"the skill catches X" provable and regression-gated, not claimed.

This is the reference eval layout for every review skill in this repo — copy it.

## Layout

```
evals/
  README.md            ← this file
  cases/
    <case-name>/
      <input file>     ← Dockerfile or docker-compose.yml fixture
      expected.txt     ← one rule ID per line the skill MUST report (empty = clean)
  validate.sh          ← static consistency check (CI-runnable, no model needed)
```

## Two layers of checking

1. **Static validation (`validate.sh`, CI-runnable now).** Asserts every ID in
   every `expected.txt` exists in the skill's Rule Catalog, and that the `clean/`
   case expects nothing. Catches typos, renamed/deleted rules, and drift between
   the catalog and the evals. No model invocation.

2. **Model grading (manual / harness).** Run the `/docker review` skill against
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
bash skills/docker/evals/validate.sh
```

Exit non-zero on any unknown rule ID or a non-empty `expected.txt` in a `clean-*`
case. Runs in CI (`scripts/check-evals.sh`) alongside `scripts/generate.sh --check`.

## Run behavioral (Tier-2) validation

```bash
EVALS=1 bash scripts/run-behavioral-evals.sh docker
```

Actually invokes `/clouddrove:docker review` against each fixture via `claude -p`
and diffs live output against `expected.txt` — catches a real regression (skill
stops detecting a violation), not just doc drift. Opt-in: spends API tokens, not
wired into the free CI gates. Run manually or on a nightly schedule.

`clean-suppressed-root-user` proves the `docker-skill:ignore` suppression
convention is honored. `clean-buildstage-root-final-nonroot` proves the skill
doesn't over-trigger on the new FP-exclusion list in `SKILL.md` — a root build
stage that never ships is explicitly excluded from `CICD-DOCK-002`.

## Adding a case

1. `mkdir cases/<descriptive-name>/`
2. Drop a fixture (`Dockerfile` or `docker-compose.yml`) that violates (or cleanly
   passes) specific rules.
3. Write `expected.txt` — one rule ID per line, the IDs the skill must report.
   Empty file for a clean fixture.
4. `bash validate.sh` → green.
