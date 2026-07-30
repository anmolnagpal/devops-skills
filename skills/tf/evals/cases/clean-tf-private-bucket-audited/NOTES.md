# clean-tf-private-bucket-audited

The correct form of `bad-tf-public-bucket-no-audit-logs`, resource for resource, so
the pair isolates exactly what each of the three new rules keys on.

- `SEC-PUB-001` — the public-read ACL is gone and
  `aws_s3_bucket_public_access_block` sets all four flags `true`. All four matter:
  the rule fires if any one is explicitly `false`, because `block_public_acls` alone
  still leaves the policy path open and vice versa. Note the rule does *not* fire on
  a bucket that simply omits the resource, which is why `clean-suppressed-hardcoded-region`
  stays clean with a bare `aws_s3_bucket`.
- `SEC-LOG-001` — an `aws_cloudtrail` with `enable_logging = true`, multi-region and
  including global service events. A trail with `enable_logging = false` would still
  fire, which is the case the rule names alongside outright absence.
- `SEC-LOG-002` — an `aws_flow_log` covering `aws_vpc.main` with `traffic_type =
  "ALL"`.

Nothing else may fire either: remote backend with locking and encryption, pinned
versions, `locals` tags on every taggable resource, described and typed variables,
described outputs, no hardcoded region or CIDR.

Two corrections were needed here after a Tier-2 run, and both were mine. Every
resource name originally hardcoded `acme-prod-`, which is `TF-VAR-004` (a hardcoded
environment name), so they now interpolate `var.client` and `var.environment`. And
the trail, flow log, and bucket are declared directly rather than through community
modules, which is `TF-MOD-001`, now suppressed with a reason. Writing a "clean" case
that is not clean is the same defect this suite caught in an older fixture the same
day; it is easy to do and only a live run finds it.

Note there is no `.tfstate` in this directory. That absence is the point of the
contrast with `bad-tf-state-committed`, which is otherwise a competent module too.
