# bad-tfplan-unbound-apply

Two findings that source review structurally cannot see.

`TF-PLAN-002` — `aws_db_instance.replica` carries a literal `password` in
`change.after`, and `after_sensitive.password` is `false`, so the value is not
redacted. Anyone with read access to the CI logs or the plan artifact has the
production database password. The `.tf` source may well have sourced it from a
variable; that is not the point, and `/clouddrove:tf`'s `TF-VAR-001` would not fire
on it.

`TF-PLAN-006` — the plan job writes `-out=tfplan` and the apply job never receives
it. There is no `actions/upload-artifact` and no `download-artifact`, so
`terraform apply -auto-approve` re-plans against current state and applies that
instead. Reviewing the plan job's output gives false assurance. Exclusion 7 does
not apply: job ordering via `needs:` is not artifact binding, and there is no
Terraform Cloud, Atlantis, or Spacelift run providing the guarantee.

`aws_ssm_parameter.db_url` must NOT be reported. It looks credential-shaped and it
is a SecureString, but `after_sensitive.value` is `true`, so the value is redacted
in output. That is exclusion 6, and it is the pair that separates "a secret is
readable" from "a secret exists".

Must NOT fire: `TF-PLAN-001` (both actions are pure `create`; the db instance is
data-bearing but nothing is being destroyed), `TF-PLAN-003`, `TF-PLAN-004`,
`TF-PLAN-005`.
