# Tier-2 eval results

Tier-1 (`scripts/validate.sh`, always in CI) checks that the eval documents are
internally consistent. It never runs a skill. Tier-2
(`scripts/run-behavioral-evals.sh`, opt-in, spends API tokens) actually invokes
each skill and grades the output.

This file records Tier-2 runs, because an unrecorded run is a memory rather than
evidence, and the gap between "100% of rules have a fixture" and "100% of rules
were observed firing" is exactly where a testing story goes soft.

---

## 2026-07-29 — first run

**60/63 cases passed.** Plugin 1.4.0, `claude -p`, one call per case.

| Suite | Cases | Result |
|---|---|---|
| appsec | 4 | pass |
| ci | 4 | pass |
| docker | 7 | 1 failure |
| github-actions | 4 | pass |
| gitops | 5 | pass |
| incident | 4 | pass |
| k8s | 10 | pass |
| observability | 5 | pass |
| tf | 8 | 2 failures |
| tf-plan | 5 | pass |
| wrapper-tf | 7 | pass |

All three failures were **defects in the evals or the skills, not model
misbehavior.** In each case the model's output was defensible and the
expectation was not.

### 1. `docker/bad-dockerfile-root-latest-secret` — missing `CICD-DOCK-013`

Found 11 of 12 expected IDs, declining "no `.dockerignore`". The rule is about a
`.dockerignore` missing from the build context root, and the case is a directory
holding one `Dockerfile`, which is not evidence about any real build context.
Asserting the absence would have been a guess.

The skill had no scoping guidance on this rule, unlike `SEC-K8S-004` and the
`OBS-*` absence rules which explicitly say to assess only when the containing
thing is visible. Fixed by adding that exclusion, dropping the undeterminable
expectation, and adding `bad-docker-incomplete-dockerignore` for the half of the
rule that needs no caveat: a `.dockerignore` that exists and omits `.git`,
`node_modules`, `.env`.

This expectation shipped in PR #12 and was green for months. Tier-1 only checks
that expected IDs exist in the Rule Catalog, so an expectation can be
**impossible to satisfy** and still pass indefinitely.

### 2. `tf/clean-iam-scoped-mfa-condition` — false positive `SEC-IAM-001`

The statement contains `Resource = "*"`, which is exactly what the rule names, so
the model was right to flag it. What makes it acceptable is that
`aws-portal:*Billing` and `aws-portal:*Usage` accept no resource ARN at all: AWS
rejects any policy that scopes them, so `Resource = "*"` is the only spelling AWS
takes.

The skill had no exclusion expressing that, so the eval encoded an assumption the
skill never stated. Exclusion 6 now states it, deliberately narrowly:
`Action = "*"` is never excluded, nor is `Resource = "*"` beside a mutating action
that does accept an ARN, and read-only intent is not a constraint unless the
actions are named and genuinely non-scopable.

### 3. `tf/clean-suppressed-hardcoded-region` — false positive `TF-MOD-001`

Reported `TF-MOD-001` on a raw `aws_s3_bucket`, which the skill's own example
output names as that exact finding. The case suppressed `TF-VAR-004` and nothing
else, so it was mislabeled clean rather than wrongly reported. Now suppresses both
with reasons, which makes it prove something new: two suppressions on one resource
are both honored.

Its provider pin also moved `~> 5.0` to `~> 6.0`, because `region` is not a
settable argument on `aws_s3_bucket` in provider 5.x. The fixture would not have
planned.

### A defect in the harness itself

The installed plugin was **1.3.0** when this run started, against a 1.4.0 tree.
Had it not been caught, the four skills added in 1.4.0 would have been silently
absent while the run appeared to pass, and a green result would have reported the
repo as verified while testing code that was not in it.

`run-behavioral-evals.sh` now asserts the installed plugin version equals
`plugin.json` and refuses to run otherwise. This was the most useful finding of
the run, and it came from running the harness rather than from any case in it.

### What held

- **Zero false positives across 22 `clean-*` cases** after the two above were
  corrected, including the traps: a `{{revision}}` template variable that reads as
  unpinned, provider-normalized `tags_all` that reads as drift, a ticket-tier
  alert that needs no runbook, a node agent's `readOnly` `hostPath`.
- **`bad-obs-no-alert-route` passed**, which is the hardest inference in the set:
  read a `PrometheusRule`, extract its `team` label, walk the Alertmanager route
  tree, and conclude the page falls through to a `null` receiver.
- **Suppression semantics held.** Every `bad-*-suppression-no-reason` case
  reported both `META-SUP-001` and the underlying rule, which is the semantic
  defined in prose only. It was not guaranteed the model would honor it.

---

## Running it yourself

```bash
EVALS=1 bash scripts/run-behavioral-evals.sh              # all suites, ~60 min
EVALS=1 bash scripts/run-behavioral-evals.sh tf k8s       # named suites
EVALS=1 bash scripts/run-behavioral-evals.sh --triggers   # descriptions, not rules
```

Model output is non-deterministic, so a single failure is a signal to investigate
rather than proof of a regression. Re-run the case before changing anything. What
this run showed is that when a case does fail, the eval is at least as likely to
be wrong as the skill.
