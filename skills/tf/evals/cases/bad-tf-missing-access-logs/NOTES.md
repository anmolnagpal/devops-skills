# bad-tf-missing-access-logs

An internet-facing application load balancer (`internal = false`,
`load_balancer_type = "application"`) with no `access_logs` block — the public
edge keeps no record of who connected. Trips **SEC-LOG-006**.

Everything else is clean (pinned providers, remote backend, required tags,
`TF-MOD-001` suppressed with a reason) so the case isolates the access-log rule.
The clean twin adds `access_logs { enabled = true }`.
