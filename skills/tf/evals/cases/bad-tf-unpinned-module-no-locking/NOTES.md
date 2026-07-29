# bad-tf-unpinned-module-no-locking

Five rules that had no fixture in this suite, on a configuration that reads as
competent: real module, real tags, described and typed variables, a remote backend.

- `TF-PROV-002` — the `terraform` block contains only a `backend`. No
  `required_version`, no `required_providers`, so provider resolution is whatever the
  running machine last cached.
- `TF-MOD-002` — the VPC module is sourced from a git URL pinned to `?ref=master`,
  which is a moving branch rather than a version. This is the git-ref form of the
  rule rather than the omitted-version form, which is the one people argue is fine.
- `TF-STATE-002` — the S3 backend has no `dynamodb_table`, so two concurrent applies
  can interleave. ADVISORY per this skill's catalog.
- `TF-OUT-002` — `db_credentials` outputs a Secrets Manager `secret_string` with a
  description and no `sensitive = true`. Note the *variable* feeding it is correctly
  marked `sensitive`, which is exactly how this slips through: sensitivity does not
  propagate to outputs, and Terraform will print the value on apply.
- `TF-QUAL-001` — the same four-key tag map is repeated three times with no `locals`
  block. ADVISORY.

Must NOT fire: `TF-STATE-001` (a remote S3 backend exists), `TF-VAR-003` (every
variable has a description and a type), `TF-VAR-002` (`db_credentials_json` is marked
sensitive), `TF-RES-001` (all four required tags on every taggable resource),
`TF-OUT-001` (both outputs have descriptions), `TF-MOD-001` (a module is used rather
than raw resources), `TF-VAR-004` (the AZ list is a legitimate in-region constant and
the CIDRs are threaded through variables).

`vpc_id` is a deliberate control: an output with a description holding nothing secret
must raise neither output rule.
