# Trigger-phrase evals: github

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers github`.

## Should load

- "audit this repo's settings"
- "set up branch protection"
- "add a CODEOWNERS file"
- "is Dependabot configured?"
- "cut a release"

## Should not load

- "review my workflow file" → `github-actions`, workflows not settings
- "review my PR diff" → the review skill for that artifact
