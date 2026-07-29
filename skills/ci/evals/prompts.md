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

## Should not load

- "review my GitHub Actions workflow" → `github-actions`, different platform
- "review my Argo CD Application" → `gitops`
