# Trigger-phrase evals: github-actions

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers github-actions`.

## Should load

- "review my workflow"
- "are my actions pinned?"
- "set up OIDC to AWS instead of static keys"
- "check .github/workflows for injection risks"
- "why can a fork PR read my secrets?"

## Should not load

- "review my .gitlab-ci.yml" → `ci`, different platform
- "set up branch protection" → `github`, that is repo settings not workflows
