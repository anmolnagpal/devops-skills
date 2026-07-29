# clean-tfplan-additive

Nothing may fire. A routine prod deploy: two new resources, one ECS task
definition revision bump, one no-op.

The verdict line should read `SAFE TO APPLY`. This case is as much about the
verdict as the findings, since a plan reviewer that hedges on a clean plan is
useless in the one situation where a fast answer matters.

Precision traps included on purpose:

- The `no-op` log group is data-bearing by type and its `tags_all` differs from
  `tags` by a provider-injected `ManagedBy` default. That is exclusion 3, provider
  normalization, not `TF-PLAN-003` drift.
- Four resource changes is well under the `TF-PLAN-004` threshold of 25, and all
  four sit in one environment.
- `aws_iam_role_policy` is security-relevant and might tempt a security finding,
  but this skill's catalog has no rule for policy content. That belongs to
  `/clouddrove:tf` (`SEC-IAM-001`) reading the source. Reporting it here would be
  a scope violation, not thoroughness.
- The ECS `update` changes `task_definition` only, in place, with no
  `replace_paths`. An update is not a replacement.
