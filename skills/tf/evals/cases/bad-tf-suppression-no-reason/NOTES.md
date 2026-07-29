# bad-tf-suppression-no-reason

`tf-skill:ignore TF-VAR-002` with no `-- reason`, above `sensitive = false` on a
database master password variable.

Both fire: `META-SUP-001` for the unreasoned suppression and `TF-VAR-002` for the
unmarked sensitive variable, because a suppression missing its reason does not
suppress anything. With `sensitive = false`, the password appears in plan output
and in CI logs, which is exactly the consequence `TF-VAR-002` exists to prevent.

This case also gives `TF-VAR-002` its first fixture in this suite.

Everything else is deliberately correct so nothing else can fire: remote S3 backend
with a DynamoDB lock table and encryption, provider and Terraform version pinned,
`required_providers` present, tags via `locals`, the variable has a description and
a type, and the stateful resource carries `prevent_destroy`.

Note the password is threaded from a variable rather than hardcoded, so `TF-VAR-001`
must NOT fire. The defect here is the missing `sensitive` marker, not the sourcing.
