# Contributing

Thanks for your interest. This repo is a community-friendly collection of DevOps skills for AI coding tools — issues and PRs are welcome.

## Add or improve a skill

1. Skills live in `skills/<name>.md` (single canonical source).
2. Frontmatter must include `name`, `description`, `metadata`, and `paths` (when the skill should auto-trigger on file globs).
3. Body should follow the structure: a short purpose paragraph, a Keywords section, an Output Artifacts table, then sections per mode (REVIEW / NEW / etc.).
4. Use `/skill-creator` (this repo) to iterate on the skill and run evals.
5. Run `bash scripts/generate.sh` — this rebuilds `.cursor/rules/<name>.mdc` and `AGENTS.md` from your source.
6. Commit `skills/<name>.md`, the new `.cursor/rules/<name>.mdc`, and the updated `AGENTS.md`.
7. Update the skill table in `README.md`.

## Open a pull request

- One skill (or one focused fix) per PR.
- Include a brief example of the kind of output the skill should produce.
- The `test` workflow will fail if generated adapters are out of sync — fix locally with `scripts/generate.sh`.

## Promote a backlog spec

`skills/specs/` contains spec drafts that have not been authored as runnable skills yet. To promote one:

1. Pick a spec (e.g. `skills/specs/aws-cost.md`).
2. Create `skills/aws-cost.md` with proper frontmatter.
3. Distill the spec into actionable instructions following the structure above.
4. Delete the spec file once superseded.

## Code of conduct

Be kind. Critique ideas, not people. No spam, no off-topic, no sales.

## License

By contributing you agree your work is licensed under the MIT License (see `LICENSE`).
