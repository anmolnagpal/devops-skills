# Persisted review reports

Every review skill answers in chat by default. Ask it to save the review and you get
this format, written to a conventional path, so a review becomes an artifact you can
diff, attach to a PR, or hand to an auditor six months later.

```text
"review my terraform and save the report"
"save that review to docs/reviews/"
```

## Why the skills do not write it themselves

Eleven review skills are `safety: read-only`, with `allowed-tools` limited to `Glob`
and `Read`. That is enforced by `scripts/check-skills.sh` and stated in the README,
and it is worth more than the convenience of a skill writing its own output: a
reviewer that cannot modify your repo is a reviewer you can run without reading its
diff first.

So the skill produces the report **content** and names the path. The write is done by
the session, which already has that permission because you asked for it. Nothing in
the skill's blast radius changes, and you keep the ability to read the report before
it lands.

Only `adr` and `incident` write files directly, because producing a document *is*
their output rather than a side effect of reviewing.

## Path convention

```
docs/reviews/<skill>-<YYYY-MM-DD>.md          # one review
docs/reviews/<skill>-<YYYY-MM-DD>-<n>.md      # second run the same day
docs/reviews/readiness-<service>-<date>.md    # deploy gate, keyed by service
```

Predictable rather than clever, so two runs sort next to each other and
`diff docs/reviews/tf-2026-07-01.md docs/reviews/tf-2026-07-29.md` answers "what did
we fix and what did we add" without any tooling.

Commit them or gitignore them, but pick one per repo. Committed reports give you the
audit trail and the diff; ignored ones keep the noise out of PRs. Committing is the
better default for anything a compliance process will ask about later.

## Format

```markdown
---
skill: tf
skill_version: 1.4.0
date: 2026-07-29
commit: 4bf0b0c
target: prod
blocking: 3
advisory: 2
suppressed: 1
---

# Terraform review — prod — 2026-07-29

**Scope:** 14 files under `environments/prod/`, `_modules/`
**Verdict:** DO NOT MERGE — 3 blocking

## BLOCKING (3)

| Rule | Location | Finding | Fix |
|---|---|---|---|
| `TF-STATE-001` | `main.tf:14` | No remote backend, state would live on a laptop | Add `backend "s3"` with a DynamoDB lock table |
| `TF-VAR-001` | `rds.tf:31` | DB password hardcoded in `default` | Move to a variable, mark `sensitive`, source from Secrets Manager |
| `TF-PROV-001` | `versions.tf:1` | Provider not version-pinned | Pin `aws ~> 6.0` |

## ADVISORY (2)

| Rule | Location | Finding | Fix |
|---|---|---|---|
| `TF-RES-001` | `s3.tf:8` | Bucket missing required tags | Add `Environment`, `Team`, `ManagedBy` |
| `TF-VAR-003` | `variables.tf:5` | `instance_type` has no description or type | Add both |

## Suppressions honored (1)

| Rule | Location | Reason given |
|---|---|---|
| `TF-RES-002` | `volumes.tf:22` | Scratch volume, lifecycle intentionally absent, see ADR-0007 |

## Not assessed

- `TF-MOD-001` — no raw AWS resources in scope, nothing to compare against a module.
- Live-state rules — this is a source review; run `/clouddrove:tf-plan` against the
  plan for anything that depends on current state.
```

## Rules for the report

**Frontmatter is the machine-readable half.** Counts and `commit` are what let CI or
a script compare two reports without parsing prose. Keep the keys stable.

**One table row per finding, never a paragraph.** Prose findings cannot be diffed,
counted, or deduped, which defeats the point of persisting them.

**Suppressions get their own section, with the reason.** A report that silently omits
suppressed findings reads as a cleaner repo than you have. The reason being visible
is also what makes a bad suppression easy to spot in review.

**"Not assessed" is mandatory when anything was skipped.** A rule that did not apply,
a file that could not be read, a check needing live state. Silence about scope is how
a report gets mistaken for a guarantee.

**Never edit an old report.** Write a new one. The value is in the sequence, and a
rewritten report is a lost baseline.

## Diffing two runs

```bash
diff docs/reviews/tf-2026-07-01.md docs/reviews/tf-2026-07-29.md
grep -c '^| `' docs/reviews/tf-*.md          # findings per run, oldest to newest
grep -h '^| `' docs/reviews/tf-2026-07-29.md | grep -oE '`[A-Z-]+[0-9]+`' | sort | uniq -c
```

Rule IDs are stable across skills and across auditkit, so a finding that appears in a
`tf` report and later in an audit is the same finding, and one that disappears was
either fixed or suppressed. The suppressions section tells you which.
