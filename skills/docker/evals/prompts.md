# Trigger-phrase evals: docker

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers docker`.

## Should load

- "review my Dockerfile"
- "why is my image 1.2GB?"
- "reduce this image size"
- "my container exits immediately, what is wrong?"
- "set up compose for local dev"

## Should not load

- "review my helm values" → `k8s`
- "review my build workflow" → `github-actions`
