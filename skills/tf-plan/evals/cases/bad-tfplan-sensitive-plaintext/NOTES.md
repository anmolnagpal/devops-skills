# Marked-sensitive plaintext in plan JSON

The inert fixture value models a credential serialized in `change.after.value`.
`after_sensitive.value` is true, but the value remains readable. Report
`TF-PLAN-002` at `aws_ssm_parameter.db_password`, attribute `change.after.value`,
without repeating the value in the finding. Metadata is not artifact redaction.

The SSM entry in `bad-tfplan-unbound-apply` is the omitted-value control. It
contains no readable value and must remain silent for that resource. This new
case only creates a resource and provides no apply workflow, so do not invent
destruction, drift, version changes, or an unbound apply finding.

Primary source: [HashiCorp show command](https://developer.hashicorp.com/terraform/cli/commands/show).
