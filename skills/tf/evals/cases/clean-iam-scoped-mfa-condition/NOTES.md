# clean-iam-scoped-mfa-condition

Nothing may fire, and the reason is narrower than it looks. This case failed a
Tier-2 run on 2026-07-29 by reporting `SEC-IAM-001`, and the model was defensible:
the statement really does contain `Resource = "*"`, which is exactly what the rule
names.

What makes it acceptable is that `aws-portal:*Billing` and `aws-portal:*Usage`
accept no resource ARN at all. AWS rejects any policy that tries to scope them, so
`Resource = "*"` is not over-permission here, it is the only spelling AWS will
take. The statement is constrained the only way it can be: a
`BoolIfExists` condition requiring `aws:MultiFactorAuthPresent`, on a
human-facing `aws_iam_group`.

The skill previously had no exclusion expressing that, so the eval encoded an
assumption the skill never stated. Exclusion 6 now does, and it deliberately
refuses to generalise: `Action = "*"` is never excluded, and `Resource = "*"` beside
a mutating action that does accept an ARN is still a finding. Read-only intent is
not a constraint unless the actions are named and genuinely non-scopable.

`SEC-IAM-003` must also stay silent. The policy is attached to a group, which is
human-facing, so exclusion 5 does not apply — the MFA condition is present, which
is what the rule wants.
