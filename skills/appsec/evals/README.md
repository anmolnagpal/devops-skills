# Appsec skill evals

Eval-driven development for the `/clouddrove:appsec` review mode. Each case is an
**input fixture** plus the **exact rule IDs** the skill must surface on it. This
makes "the skill catches X" provable and regression-gated, not claimed.

This is the reference eval layout for every review skill in this repo — copied
from `/tf`'s.

## Layout

```
evals/
  README.md            ← this file
  cases/
    <case-name>/
      <input file(s)>  ← manifest/lockfile/config fixture
      expected.txt     ← one rule ID per line the skill MUST report (empty = clean)
  validate.sh          ← static consistency check (CI-runnable, no model needed)
```

## Two layers of checking

1. **Static validation (`validate.sh`, CI-runnable now).** Asserts every ID in
   every `expected.txt` exists in the skill's Rule Catalog, and that the `clean-*`
   case expects nothing. Catches typos, renamed/deleted rules, and drift between
   the catalog and the evals. No model invocation.

2. **Model grading (manual / harness).** Run the `/clouddrove:appsec` skill against
   each `cases/<name>/` input and compare reported rule IDs to `expected.txt`:
   - **Recall (the pass/fail gate):** every ID in `expected.txt` MUST be reported.
     A missing one = false negative = case fails. `expected.txt` is the
     must-catch contract, not an exhaustive list.
   - **Precision (tracked, not gated):** extra *defensible* findings don't fail a
     case; a clearly *wrong* finding does.
   - **Clean cases are exact:** a `clean-*` case fails on ANY reported finding.

   `pass@k` = fraction of runs meeting the recall gate. `scripts/run-behavioral-evals.sh`
   (below) is that harness — the fixtures + expected files are the contract it consumes.

   Note: `SEC-DEP-001`'s fixture here documents an audit tool's expected output
   (the tool call itself needs network/registry access and isn't reproducible in
   a static fixture) — the model-grading run for that case should mock or record
   the audit command's output rather than requiring a live run.

## Run static validation

```bash
bash skills/appsec/evals/validate.sh
```

Exit non-zero on any unknown rule ID or a non-empty `expected.txt` in a `clean-*`
case. Runs in CI (`scripts/check-evals.sh`) alongside `scripts/generate.sh --check`.

## Run behavioral (Tier-2) validation

```bash
EVALS=1 bash scripts/run-behavioral-evals.sh appsec
```

Actually invokes `/clouddrove:appsec` against each fixture via `claude -p` and
diffs live output against `expected.txt` — catches a real regression (skill stops
detecting a violation), not just doc drift. Opt-in: spends API tokens, not wired
into the free CI gates. Run manually or on a nightly schedule.

## Adding a case

1. `mkdir cases/<descriptive-name>/`
2. Drop a fixture (manifest/lockfile/config) that violates (or cleanly passes)
   specific rules.
3. If the fixture is a real dependency manifest (`package.json`,
   `package-lock.json`, `go.sum`, `Gemfile.lock`, etc.) with an intentionally
   vulnerable/outdated version, name it with a `.fixture` suffix
   (`package.json.fixture`) instead of the real filename. GitHub's dependency
   graph / Dependabot security updates parses real manifest filenames
   repo-wide regardless of `.github/dependabot.yml` scope, and will open a
   real bump PR against an intentionally-vulnerable fixture otherwise — this
   happened once (see repo PR history) before this convention existed.
4. Write `expected.txt` — one rule ID per line, the IDs the skill must report.
   Empty file for a clean fixture.
5. `bash validate.sh` → green.
