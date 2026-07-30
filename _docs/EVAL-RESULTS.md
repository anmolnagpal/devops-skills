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

## 2026-07-29 — first `--triggers` run

**103/119 prompts routed as declared**, then iterated. Three distinct causes, and
only one of them was the skills.

| Cause | Count |
|---|---|
| A bug in this harness | 5 |
| Real description defects | 8 |
| Bad expectations in `prompts.md` | 3 |

### The harness bug

`tr -cd 'a-z-'` stripped digits, so the model's correct answer `k8s` was read as
`ks` and five correct answers were scored as failures. `k8s` went 2/7 to 7/7 on the
one-character fix. Worth stating plainly: the largest single cause of failures in
the first run of a new harness was the harness.

### The real defects had one shape

Every collision was **under-claiming by the skill that should have won**, not
over-claiming by the one that did. `deploy` and `observability` both scored 7/7
while absorbing traffic meant for `ci` and `incident`.

| Skill | Lost to | Because |
|---|---|---|
| `ci` | `deploy` | never claimed stages, jobs, or credentials |
| `incident` | `observability` | never claimed on-call readiness or alerts-without-runbooks |
| `owasp` | `appsec` | never claimed injection or secret storage as judgment calls |
| `github` | `none` | claimed 'create a release' but not 'cut a release' |
| `skill-creator` | `tf` | never claimed running evals |

Verified after fixing: `owasp` 5/7 to 7/7, `k8s` 2/7 to 7/7, `tf` 7/9 to 8/8,
`incident` 5/7 to 6/7, `skill-creator` 5/7 to 7/8, `ci` 5/7 to 4/7 to 5/7.

### Two lessons that cost a regression each

**Naming a neighbour's territory inside your own description hands them the
traffic.** The first `ci` fix ended with "/clouddrove:deploy owns rollout strategy
and readiness gating", and `ci` promptly lost "is my pipeline gated before prod?",
which it had been winning. Removing the clause recovered it. `owasp` names `appsec`
and did not regress, because the words it attributes ("lockfile CVEs, missing
headers, wildcard CORS") do not appear in its own trigger phrases. The rule is
narrow: a disambiguation clause must not use vocabulary you are trying to win.

**A phrase in both sections always fails.** "review my infra" ended up in `tf`'s
Should-load and Should-not-load lists at once, because a deletion missed by three
words. It failed both ways until removed. `check-prompts.sh` does not catch this
and could.

### Known limits of this proxy, measured not assumed

Two `ci` prompts still fail with their exact phrases verbatim in the description:
"add a helm deploy stage" and "why does staging deploy with prod credentials?".
Both route to `deploy`. They are kept, because the expectations are right and the
measurement is what is limited:

1. **A forced pick from a flat list over-weights one salient word.** "deploy" and
   "release" beat the rest of the sentence regardless of what the correct skill
   claims.
2. **No file context.** Most skills trigger partly on globs, and `ci` owns
   `**/.gitlab-ci.yml`, which would settle both prompts in reality. The proxy
   discards that signal.

So a `--triggers` failure means "this description does not compete for its own
vocabulary", not "the harness will not load this skill". Tuning a description past
the point where it reads well to a human is fitting the skill to the measurement
instead of the job, and these two cases are where that line sits.

The composed per-suite figures above come from targeted re-runs after each fix, not
from one clean pass. A single full re-run would give one comparable number and has
not been done yet.

---

## 2026-07-29 — verifying four new tf rules

`tf` suite only, run twice. First pass 9/11, second 11/11.

Both bad cases passed on the first attempt: `SEC-PUB-001`, `SEC-LOG-001`,
`SEC-LOG-002`, and `TF-STATE-003` all fired where expected, including the two
absence rules under their new visibility scoping and `TF-STATE-003` on a committed
state file. Both failures were in **clean** cases, and both were mine.

### The rule was wrong, not the fixture

`SEC-PUB-001` was written to fire when `aws_s3_bucket_public_access_block` is
absent. That is factually wrong: since April 2023 AWS enables Block Public Access on
new buckets by default and disallows ACLs, so a bucket with no block resource and no
public grant is private. As written the rule would have flagged every plain private
bucket in every repo as a BLOCKING public-exposure finding, and it immediately broke
`clean-suppressed-hardcoded-region`, a case that had passed all day.

Narrowed to affirmative exposure: a public ACL, a `Principal: "*"` policy, or a block
resource that explicitly sets a flag `false`. Whether an older pre-2023 bucket is
genuinely exposed is a live-state question and belongs to auditkit.

A false-positive generator, caught by a ten-minute run before it shipped.

### The clean fixture was not clean

`clean-tf-private-bucket-audited` fired `TF-MOD-001` and `TF-VAR-004`, both true
positives: every resource name hardcoded `acme-prod-`, and the trail, flow log, and
bucket were declared directly rather than through modules. Names now interpolate
`var.client` and `var.environment`, and `TF-MOD-001` is suppressed with a reason.

This is the same defect corrected in an older fixture earlier the same day,
committed again hours later by the person who fixed it. Writing a clean case that is
not clean is easy, invisible to Tier-1, and only a live run finds it. It is the
strongest argument for running Tier-2 on any change that adds a rule.

### The content-hash guard earned itself twice

Both runs above were initially refused: the version stayed 1.4.1 while the skill
body changed, so `claude plugin update` was a no-op and the suite would have tested
the previous rules. The guard named the reinstall, the reinstall fixed it, and the
hash moved `f1065df7050c` to `ce480a797dcc` to `74e2969c544f` across the three
states. A version field cannot see any of that.

---

## Schedule

`.github/workflows/behavioral-evals.yml` runs both suites weekly (Mondays, 04:17 UTC)
and on demand via workflow_dispatch, where you can pick a suite and a pass count.

It needs `ANTHROPIC_API_KEY` in the repository's Actions secrets. Without it the job
warns and skips rather than failing, so a fork without the secret is not permanently
red. A scheduled failure files an issue labelled `evals` pointing at the logs.

Weekly rather than nightly because a pass costs roughly 70 calls for the fixtures and
120 for the triggers. The point is catching decay within a week, not within a day.

The workflow installs the plugin **from the checkout**, not from the published
marketplace, because the harness refuses to run unless the installed copy matches the
tree by version and content hash.

## Trend

A pass or fail per run says nothing about direction. A score drifting from 60/63 to
57/63 over a month is the signal worth having, and it is invisible if each run only
reports its own outcome.

Each scheduled run therefore posts a line to a single pinned issue titled
**Behavioral eval trend**, one comment per run, oldest first, with both suite scores
and a link to the run. It also writes a table to the job summary, so a run's outcome is
legible without downloading an artifact.

Deliberately an issue rather than a committed file. Having CI write to `main` to record
that CI passed adds a commit per week, a permission the workflow does not otherwise
need, and a merge conflict surface, to store data that is already chronological in the
issue timeline.

Subtract the known-failing cases below before reading a score as a regression.

## Distinguishing a flake from a regression

Model output is non-deterministic, so a single failing run proves little:

```bash
EVALS=1 bash scripts/run-behavioral-evals.sh --repeat 3 tf
EVALS=1 bash scripts/run-behavioral-evals.sh --triggers --repeat 3
```

A case that fails in some passes and not others is a flake. One that fails every pass
is a regression. Two of the known-failing trigger prompts were confirmed this way:
`adr`'s "should we use EKS or ECS?" failed in both passes of a pass@2, which
established it as a stable proxy artifact rather than noise.

## 2026-07-30 — first pass@3, and a defect in the pass@N reporting

Pass 1 scored **112/120** with 8 failures. Passes 2 and 3 never ran: the tree was
edited while pass 1 was in flight, so the content-hash guard refused them, correctly.

The reporting was wrong, though. The repeat loop recorded both refusals as
`pass N: FAILURES`, because a refusal and a failed run both exited 1 and the loop could
not tell them apart. A pass@3 built from one real pass and two refusals is not a pass@3,
and the weekly trend would have recorded it as a score.

Fixed by giving the harness a distinct exit code: **0** all passed, **1** ran and
something failed, **3** refused to run. The repeat loop now aborts on 3 rather than
averaging it in, and the workflow reports it as a setup fault rather than a regression.
Two lessons, one of them purely operational: do not edit `skills/` while a run is in
flight.

Pass 1's 8 failures, checked against the last measured state rather than asserted:

- **3 documented known-failing** (`adr` EKS-or-ECS, two `ci` deploy-worded prompts).
- **3 persistently failing but never documented**: `github` "cut a release",
  `skill-creator` "run the evals for the tf skill", `incident` "which alerts are missing
  runbooks". These never passed after any fix, and the known-failing table listed only
  the first three, so the table was incomplete. Now corrected below.
- **2 that differ from the last measured state**: `ci` "is my pipeline gated before
  prod?" and `incident` "are we ready to put this service on-call?". Both had passed
  after their description fixes. One pass cannot say whether they regressed or flaked,
  which is the entire reason pass@N exists, so they are recorded as unclassified rather
  than as regressions.

An earlier draft of this section claimed five prompts had regressed. That was wrong on
both the count and the characterization, and it is corrected here rather than quietly
edited, because a results file that is casual about its own history is not a record.

## Known-failing cases, deliberately kept

Three prompts fail `--triggers` every time and are left in place, because the
expectations are right and the measurement is what is limited. Deleting them would buy
a green number by hiding the case.

| Prompt | Routes to | Why it cannot be fixed by tuning |
|---|---|---|
| `"add a helm deploy stage"` | `deploy` | phrase is verbatim in `ci`'s description; the word "deploy" wins a forced pick |
| `"why does staging deploy with prod credentials?"` | `deploy` | same, and `ci` owns `**/.gitlab-ci.yml` which the proxy cannot see |
| `"should we use EKS or ECS?"` | `adr` | `adr` says it records rather than decides; nothing among 17 skills owns "help me decide", so a forced pick lands here by elimination |
| `"cut a release"` | `deploy` / `none` | `github` claims the phrase verbatim; "release" reads as shipping, and the proxy cannot see that `github` owns `**/CODEOWNERS` and `dependabot.yml` |
| `"run the evals for the tf skill"` | `tf` | the prompt names `tf`, so a router matching on skill names picks it over the skill that operates *on* skills |
| `"which alerts are missing runbooks"` | `observability` | genuinely straddles the seam: observability owns alerts, incident owns runbooks, and this asks about both at once |

Two more are **unclassified** rather than known-failing: `ci` "is my pipeline gated
before prod?" and `incident` "are we ready to put this service on-call?". Both passed
after their description fixes and failed in the single usable pass of the first pass@3.
A clean pass@3 is needed to say whether they regressed or flaked. Do not tune either
until that number exists.

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
