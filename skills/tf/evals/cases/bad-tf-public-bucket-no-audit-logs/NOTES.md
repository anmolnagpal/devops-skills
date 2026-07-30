# bad-tf-public-bucket-no-audit-logs

Three rules that had no skill behind them until now, on a configuration that is
otherwise careful: remote backend with locking and encryption, pinned versions,
`locals` tags on every resource, described and typed variables, described outputs.
A reviewer checking style passes this and the customer documents are world-readable.

- `SEC-PUB-001` — `aws_s3_bucket_acl` sets `acl = "public-read"` on a bucket named
  `acme-prod-customer-documents`, and no `aws_s3_bucket_public_access_block` exists
  to override it. Exclusion 7 explicitly cannot rescue this: nothing in the file
  states public intent, and a bucket holding customer documents is never excluded
  however it is configured.
- `SEC-LOG-001` — no `aws_cloudtrail` anywhere in the module, so there is no record
  of who did what in this account. This is a root module with `variables.tf` and
  `outputs.tf` present, which is what makes the absence assessable under exclusion 8;
  a lone `.tf` would not be.
- `SEC-LOG-002` — `aws_vpc.main` is defined here with no `aws_flow_log` covering it,
  so there is no network record either.

Must NOT fire: `TF-STATE-001` and `TF-STATE-002` (S3 backend with `dynamodb_table`),
`TF-PROV-001`/`002` (pinned, `required_version` present), `TF-RES-001` (all four
required tags via `locals`), `TF-VAR-003` (every variable has description and type),
`TF-OUT-001` (both outputs described), `TF-QUAL-001` (`locals` used),
`TF-VAR-004` (region and CIDRs are threaded through variables, not hardcoded).
