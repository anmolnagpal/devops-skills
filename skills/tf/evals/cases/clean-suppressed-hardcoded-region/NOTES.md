# clean-suppressed-hardcoded-region

Proves the `tf-skill:ignore` convention is honored. Nothing may fire.

This case failed a Tier-2 run on 2026-07-29 by reporting `TF-MOD-001`, and the
model was right: the fixture uses a raw `aws_s3_bucket`, and the skill's own
example output names that exact case (`TF-MOD-001 Raw aws_s3_bucket used →
consider terraform-aws-modules/s3-bucket/aws`). The case suppressed `TF-VAR-004`
and nothing else, so it was mislabeled clean rather than wrongly reported.

Fixed by suppressing both rules with real reasons, which also makes the case prove
something it did not before: that **two** suppressions on one resource are both
honored, not just the first.

The provider pin moved from `~> 5.0` to `~> 6.0` at the same time. `region` is not
a settable argument on `aws_s3_bucket` in provider 5.x, only a computed attribute,
so the fixture was invalid HCL for the version it pinned. A fixture that would not
plan is a weak test of anything.
