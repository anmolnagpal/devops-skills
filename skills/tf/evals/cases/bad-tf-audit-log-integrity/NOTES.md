# bad-tf-audit-log-integrity

Root module that provisions its audit trail but leaves it forgeable and erasable.
Three distinct log-integrity defects, one per new rule:

- **SEC-LOG-003** — `aws_cloudtrail.account` has no `enable_log_file_validation`
  (no tamper-evidence) and `is_multi_region_trail = false` (activity outside the
  home region is never recorded).
- **SEC-LOG-004** — `aws_s3_bucket.audit_logs` is declared and owned here yet has
  no `aws_s3_bucket_versioning` and no `aws_s3_bucket_object_lock_configuration`,
  so the trail can be deleted (T1070). `prevent_destroy` guards Terraform, not the
  S3 API.
- **SEC-LOG-005** — `aws_eks_cluster.platform` sets
  `enabled_cluster_log_types = ["api", "authenticator"]`, omitting `"audit"`.

Everything else is intentionally clean (pinned providers, remote backend, required
tags, private bucket, `TF-MOD-001` suppressed with a reason) so the case isolates
the three audit-log rules.
