# bad-tfplan-db-replace

The case this skill exists for. `terraform plan`'s summary line would read
`1 to add, 0 to change, 1 to destroy` plus a replacement, and a reviewer skimming
it approves the apply.

`TF-PLAN-001` — `aws_db_instance.main` has `actions: ["delete", "create"]`, which
is a replace with destroy first. `replace_paths` names the cause exactly:
`availability_zone` moved eu-west-1a → eu-west-1b. The 200GB volume goes with it,
and `skip_final_snapshot: true` with a null `final_snapshot_identifier` means there
is no recovery point. The finding must state the data loss and the missing
snapshot, not just that a replacement is happening. Exclusion 2 does not apply
precisely because no snapshot exists anywhere in the plan.

Target environment is unambiguous from `variables.environment` and the
`Environment: prod` tags, so the dev relaxation does not apply. Note the fixture has
no top-level `backend` key, because real `terraform show -json` output does not have
one.

`TF-PLAN-003` — the deleted security group rule carries the description "added by
hand during the incident on 2026-06-14". It exists in state and reality but not in
code, so the apply silently reverts a human's incident fix. Drift, ADVISORY, and
worth knowing before it disappears.

Must NOT fire: `TF-PLAN-002` (no credential values anywhere in this plan),
`TF-PLAN-004` (three resource changes, one environment), `TF-PLAN-005` (provider
constraint present but unchanged), `TF-PLAN-006` (no CI workflow in this fixture,
so there is nothing to conclude about the apply path).

The log group creation must NOT be reported: it is data-bearing by type but created
in this same plan, which is exclusion 1.
