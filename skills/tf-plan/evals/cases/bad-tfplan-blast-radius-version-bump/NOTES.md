# bad-tfplan-blast-radius-version-bump

The two rules that had no fixture, and the two that a per-resource reviewer cannot
see: both are properties of the change set as a whole.

- `TF-PLAN-004` — 32 resource changes in one apply, above the rule's threshold of 25,
  and they span two environments. `module.dev_services` and `module.prod_services`
  are in the same state file (`env/shared/terraform.tfstate`), so one apply moves dev
  and prod together and a failure halfway through leaves both partially applied. The
  cross-environment half of this rule matters more than the count: 32 changes inside
  one environment would be large, while 32 across two is unrollbackable.
- `TF-PLAN-005` — the AWS provider goes `~> 5.31` to `~> 6.0`, a major bump, in the
  same apply as 32 resource changes. When something breaks there are two candidate
  causes and no way to bisect. Exclusion 5 explicitly does not apply, because the
  version bump is not the change set here; it is riding along with it.

Every individual change is benign, which is the point. Each is an in-place
`desired_count` update on an ECS service, no replacements, no deletions, so a review
that walks resources one at a time approves all 32 and reports nothing.

Must NOT fire: `TF-PLAN-001` (every action is `update`, nothing destroyed or
replaced), `TF-PLAN-002` (no credential values anywhere), `TF-PLAN-003` (no drift:
every `before` differs from its `after` only by the field the code changed),
`TF-PLAN-006` (no CI workflow in this fixture, so there is nothing to conclude about
the apply path).
