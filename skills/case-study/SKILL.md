---
name: case-study
description: "Draft, review and pre-publish check a CloudDrove client case study in the v2 format. Use when user says 'write a case study', 'draft the Wellnest case study', 'turn this project into a case study', 'review this case study before we publish', 'is this case study ready', 'check the numbers in this study', or when working in content under case-studies or outcomes. Enforces the v2 rules: client and number in the headline, three traceable numbers at the top, an attributed client quote, explicit cloud service names, and no placeholder results. This writes and audits marketing case studies; a customer-facing incident write-up belongs to incident."
safety: writes-files
metadata:
  version: 0.1.0
  author: Anmol Nagpal
  category: delivery
  updated: 2026-09-11
paths:
  - "**/case-studies/*.md"
  - "**/case-studies/**/*.md"
  - "**/outcomes/*.md"
allowed-tools:
  - Glob
  - Read
  - Write
---

# Case Study Skill

Turn a delivered engagement into a published case study that a buyer can check.
The v2 format was decided on 2026-09-11 after comparing our seven existing outcomes
against Cloudelligent, SquareOps and CloudRaft. Verdict: our writing is the strongest
of the four, our packaging is the weakest. Keep the narrative, fix the container.

## Keywords
case study, customer story, success story, outcomes, client story, reference, proof,
before and after, results, testimonial, client quote, published study, study draft

## Reference files

| Task | Read |
|------|------|
| Writing a new study | `references/template.md` |
| Checking a study before it ships | `references/checklist.md` |
| Justifying the format to someone | `references/benchmark.md` |

## The eight rules

1. Standalone page at `/case-studies/<client-slug>`. Own title, meta description,
   OG image, reading time. Never a modal.
2. Headline names the client and the number. Not "Migrating Without Disruption" but
   "Horizon Cloud: on-prem to Azure AKS, 32% lower infra cost, zero downtime".
3. At a glance block: three real numbers, engagement model, duration, stack.
4. One attributed client quote inside the page (name, title, company).
5. Cloud services named explicitly (AWS, Azure, GCP service names, not "the cloud").
   This feeds Partner Central opportunities.
6. "Agents / tools involved" line whenever an Intelligence agent, Naoru, or a
   CloudDrove open-source module was used. This is the wedge; state it where true
   and omit the line where not.
7. 800 to 1,200 words, keeping the Situation, Challenge, Before/After, What we built,
   Outcome flow.
8. Close with three takeaways, one related study, one CTA (free AI-assisted assessment).

## The number rule

**Never publish a number that cannot be traced to a report, dashboard, invoice or
client email.** This is not a style preference, it is the difference between our
studies and SquareOps publishing literal `[bracketed]` placeholders.

When drafting and a number is missing:

- Do not invent it, do not estimate it, do not soften it into an adjective.
  "Lower cost", "Stable", "Tested" are the failure mode in our current outcomes.
- Write `NUMBER NEEDED: <what, and who has it>` in the draft and list it in the
  internal notes block.
- Tell the user, in the summary, which numbers block publication.

## DRAFT, write a new study

1. **Gather the source.** Weekly reports, invoices, dashboards, the client's own
   email. For CloudDrove work the raw material lives in the Sales collection in
   Outline (Wellnest W13 to W36, Midst, ClearBasin, Contractors Intelligence School).
   Ask the user for the source if none is given; do not write from memory of the
   engagement.
2. **Pull the three numbers first.** Before any prose. If fewer than three are
   traceable, say so and name what is missing before continuing.
3. **Fill `references/template.md`.** Every section. No brackets, no TBD in the
   published body; placeholders belong in the internal notes block only.
4. **Name the services and the modules.** Specific AWS/Azure/GCP services, and our
   Terraform modules where used.
5. **Add the agents line** where an agent or open-source tool actually did work.
   Where none did, omit the line rather than stretching the claim.
6. **Leave the internal notes block in the draft.** Source docs, client approver,
   NDA status, numbers still needed, Partner Central opportunity logged (y/n). It is
   deleted at publish time, not at draft time.
7. **Report what blocks publication**: missing numbers, missing quote, missing
   written client approval.

## REVIEW, check a study before publish

Walk `references/checklist.md` top to bottom. Every box ticked or it does not ship.
Report as a list of failures, not a summary. Flag these hard stops explicitly:

- Any adjective standing in for a number in the at a glance block.
- Any `[bracket]`, `TBD` or placeholder in the body.
- A number with no traceable source in the internal notes.
- No attributed quote, or "via Upwork" as the only attribution.
- An Upwork badge anywhere on the page.
- Client naming or quote used without written approval on file.
- An AWS engagement with no launched opportunity logged in Partner Central.

## Anonymised studies

When the NDA blocks naming, the study still runs, with "a {industry} company with
{N} engineers" in place of the client name. The numbers stay. An anonymised study
with no numbers is not a case study, it is a brochure; do not publish it.
