# bad-cdtf-encryption-exposure

A prod platform stack that is structurally perfect and cryptographically open. Every
`CDTF-*` pattern rule passes: labels module present, names from
`module.labels.name_prefix`, versions pinned, `label_order` on every call, all three
required files, every variable threaded. That is the point of the fixture. A skill
that only checks the wrapper pattern reports nothing here and the repo ships an
unencrypted production database.

- `SEC-ENC-001` — Aurora `storage_encrypted = false`. Encryption at rest off on the
  primary datastore.
- `SEC-ENC-002` — two in-transit failures, one finding: ElastiCache
  `transit_encryption_enabled = false`, and the ALB serves plain HTTP on port 80
  with `enable_https_redirect = false`, so credentials cross the internet in clear
  text before anything else happens.
- `SEC-ENC-003` — the ALB is `internal = false`, so public, and no `waf_acl_arn` is
  passed to it. There is no WAF module in this stack at all, which is the stronger
  form of the finding.
- `SEC-NET-001` — EKS `cluster_endpoint_public_access = true`. ADVISORY, and
  exclusion 3 does not apply because `var.environment` is threaded into a prod
  stack; if this were a dev overlay it would stay advisory anyway, so the fixture
  states prod explicitly in its header comment.
- `OBS-MON-001` — Aurora `performance_insights_enabled = false` in prod. ADVISORY.
- `TF-OUT-002` — `aurora_master_password` is an output with a description and no
  `sensitive = true`, so the master password prints in plan output, in apply output,
  and in any CI log that captures either.

Note `at_rest_encryption_enabled = true` on ElastiCache. It must not stop
`SEC-ENC-002` firing on the same module: at-rest and in-transit are separate rules,
and getting one right is the common way the other gets missed.

`alb_dns_name` in `outputs.tf` has a description and holds nothing secret, so it must
raise neither `TF-OUT-001` nor `TF-OUT-002`.
