# GitOps skill evals

Eval-driven development for the `/clouddrove:gitops` review mode. Each case is an **input
fixture** plus the **exact rule IDs** the skill must surface on it. This makes
"the skill catches X" provable and regression-gated, not claimed.

This is the reference eval layout for every review skill in this repo — copy it.

## Layout

```
evals/
  README.md            ← this file
  cases/
    <case-name>/
      <input file>     ← Argo CD / Flux manifest fixture
      expected.txt     ← one rule ID per line the skill MUST report (empty = clean)
  validate.sh          ← static consistency check (CI-runnable, no model needed)
```

## Two layers of checking

1. **Static validation (`validate.sh`, CI-runnable now).** Asserts every ID in
   every `expected.txt` exists in the skill's Rule Catalog, and that the `clean/`
   case expects nothing. Catches typos, renamed/deleted rules, and drift between
   the catalog and the evals. No model invocation.

2. **Model grading (manual / harness).** Run the `/clouddrove:gitops review` skill against
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
bash skills/gitops/evals/validate.sh
```

Exit non-zero on any unknown rule ID or a non-empty `expected.txt` in a `clean-*`
case. Runs in CI (`scripts/check-evals.sh`) alongside `scripts/generate.sh --check`.

## Run behavioral (Tier-2) validation

```bash
EVALS=1 bash scripts/run-behavioral-evals.sh gitops
```

Actually invokes `/clouddrove:gitops review` against each fixture via `claude -p` and
diffs live output against `expected.txt` — catches a real regression (skill stops
detecting a violation), not just doc drift. Opt-in: spends API tokens, not wired
into the free CI gates. Run manually or on a nightly schedule.

`clean-gitops-pinned-appset` is where the precision of this catalog is decided.
Its `targetRevision` is the template variable `{{revision}}`, which any check
looking for a literal tag reads as unpinned; two of the three generator elements
are tags and only dev tracks a branch. It also proves the `gitops-skill:ignore`
convention is honored and that a suppression carrying a reason does not raise
`META-SUP-001`.

The pair that matters is `bad-gitops-head-prune` against
`clean-gitops-pinned-appset`. Both set `prune: true`. One adds `allowEmpty: true`
and nothing else; the other adds `allowEmpty: false`, `PruneLast=true`, and a
propagation policy. A skill that treats prune itself as the finding fails that
pair, and it fails it in the direction that gets the rule switched off.

`bad-gitops-wildcard-project` is deliberately well-run everywhere except its two
findings: pinned sources, guarded prune, selfHeal on. If a run reports anything
beyond `CICD-GITOPS-002` and `CICD-GITOPS-004` on it, the extra finding is noise
attached to a good setup.

## Adding a case

1. `mkdir cases/<descriptive-name>/`
2. Drop a fixture: an `Application`, `ApplicationSet`, `AppProject`, or Flux
   `GitRepository`/`Kustomization`/`HelmRelease` manifest.
3. Write `expected.txt` — one rule ID per line, the IDs the skill must report.
   Empty file for a clean fixture.
4. `bash validate.sh` → green.
