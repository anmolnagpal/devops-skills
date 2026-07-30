# Trigger-phrase evals: ci

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers ci`.

## Should load

- "review my .gitlab-ci.yml"
- "is my pipeline gated before prod?"
- "scaffold a terraform pipeline for GitLab"
- "add a helm deploy stage"
- "why does staging deploy with prod credentials?"

Two of the above are known to fail `--triggers` and are kept anyway:
`"add a helm deploy stage"` and `"why does staging deploy with prod credentials?"`
both route to `deploy`, and both phrases are verbatim in this skill's description.
The word "deploy" dominates a forced single pick from a flat list, and the proxy
discards the file context (`**/.gitlab-ci.yml`) that resolves it in reality. The
expectations are correct and the measurement is the limitation, so they stay:
deleting them would buy a green number by hiding the case.

## Should not load

- "review my GitHub Actions workflow" → `github-actions`, different platform
- "review my Argo CD Application" → `gitops`
