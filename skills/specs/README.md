# Specs — Backlog Skills

Spec docs imported from anmolnagpal/cloud-skills. **These are product/monetization
pitch drafts** (positioning, pricing tiers, competitive comparisons), not rule
scaffolds — none of them contain a rule catalog, BLOCKING/ADVISORY severities, or
eval fixtures. Promoting one to an active skill is closer to writing a new skill
from scratch than filling in frontmatter.

To promote a spec into a skill:
1. Pick a spec file (e.g. `aws-cost.md`) and read it for domain scope/ideas only —
   discard the pricing/positioning content, it doesn't belong in a skill body.
2. Create `skills/<name>/SKILL.md` with proper frontmatter (`name`, `description`,
   `paths`, `metadata`) following the format in the root `README.md` → "Adding a New
   Team Skill".
3. Write a real **Rule Catalog**: stable rule IDs, fixed BLOCKING/ADVISORY severity
   per rule (or state which severity model applies — see root `README.md` →
   "Severity models"), each registered in `rules/rule-ids.yaml` first
   (`check-rule-ids.sh` will reject unregistered IDs).
4. Add `skills/<name>/evals/` — at minimum one `bad-*` case and one `clean-*` case
   per major rule, plus `validate.sh` copied verbatim from an existing skill (e.g.
   `skills/tf/evals/validate.sh`). Skip only if the skill reads live state (like
   `github`/`finops`) — document why, as those skills do.
5. Run `bash scripts/generate.sh` to refresh Cursor/Codex adapters and `bash
   scripts/check-skills.sh && bash scripts/check-rule-ids.sh && bash
   scripts/check-evals.sh` to confirm it passes the same gates as every other skill.
