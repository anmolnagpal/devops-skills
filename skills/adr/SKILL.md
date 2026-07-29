---
name: adr
description: "Capture architectural decisions as structured ADRs (Architecture Decision Records). Use when user says 'record this decision', 'ADR this', 'why did we choose X', 'document this trade-off', 'we decided to...', or when a significant choice is made between alternatives (framework, database, pattern, API design, infra approach)."
safety: writes-files
metadata:
  version: 0.1.0
  author: Anmol Nagpal
  category: devops
  updated: 2026-06-10
paths:
  - "**/docs/adr/*.md"
  - "**/docs/adr/**/*.md"
allowed-tools:
  - Glob
  - Read
  - Write
---

# ADR Skill

Capture architectural decisions as they happen, so the *why* lives next to the code
instead of in a Slack thread or someone's memory. Produces lightweight ADR documents
under `docs/adr/`.

## Keywords
adr, architecture decision record, decision, rationale, trade-off, alternatives, we decided, why did we choose, design decision, supersede, decision log, nygard

## When to record a decision

- The user says "record this", "ADR this", "let's document this decision".
- A choice is made between **significant alternatives**: framework, library, database,
  language, pattern, API shape, infra/deploy approach, build vs buy.
- The user says "we decided to…" or "the reason we're doing X instead of Y is…".
- The user asks "why did we choose X?" → read and summarize the existing ADR.

For trivial or easily-reversible choices, don't create an ADR — note it inline and move on.

## Output Artifacts

| Request | Output |
|---------|--------|
| `/adr new "<title>"` | A new `docs/adr/NNNN-<slug>.md` + an updated index |
| `/adr list` | The decision log (ID, title, status, date) |
| `/adr supersede <NNNN>` | A new ADR marked as superseding an old one; old one flipped to `superseded` |

---

## Format

Lightweight Nygard ADR, adapted for AI-assisted work:

```markdown
# ADR-NNNN: <Decision Title>

**Date**: YYYY-MM-DD
**Status**: proposed | accepted | deprecated | superseded by ADR-NNNN
**Deciders**: <who was involved>

## Context

What is the issue motivating this decision? The situation, constraints, and forces at
play. 2–5 sentences.

## Decision

What we are doing. 1–3 sentences, stated clearly.

## Alternatives Considered

### <Alternative>
- **Pros**: …
- **Cons**: …
- **Why not**: the specific reason it was rejected.

(Repeat per alternative.)

## Consequences

### Positive
- …

### Negative / trade-offs
- …

### Risks
- <risk and its mitigation>
```

---

## NEW — Record a decision

1. **Initialize once.** If `docs/adr/` does not exist, ask the user to confirm before
   creating it. On confirmation, create the directory, a `README.md` seeded with the
   index table header (below), and a `template.md` copy of the format above. Never
   create files without explicit consent.
2. **Number it.** Next zero-padded number after the highest existing `docs/adr/NNNN-*.md`
   (start at `0001`). Slug = kebab-case of the title.
3. **Fill it from the conversation** — extract the decision, the context that prompted it,
   the alternatives actually weighed, and the consequences. Do not invent alternatives
   that were never discussed; if context is thin, ask one or two targeted questions.
4. **Default status** `accepted` when the user states a decision; `proposed` when still
   weighing. Date = today.
5. **Update the index** in `docs/adr/README.md`.

## Index format

`docs/adr/README.md`:

```markdown
# Architecture Decision Records

| ID | Title | Status | Date |
|----|-------|--------|------|
| [ADR-0001](0001-use-eks-over-ecs.md) | Use EKS over ECS | accepted | 2026-06-10 |
```

## SUPERSEDE — Replace a decision

1. Read the old ADR.
2. Create a new ADR that references it: "Supersedes ADR-NNNN" in Context.
3. Flip the old ADR's `Status` to `superseded by ADR-MMMM`.
4. Update both rows in the index.

Never delete or rewrite a past ADR's decision — superseding preserves the history of
*why it changed*, which is the whole point.
