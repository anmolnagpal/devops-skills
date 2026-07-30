# bad-tf-spof-db-flat-network

Four rules that were registered and emitted by nothing, on a prod configuration that
passes every check the skill had before: remote backend with locking, pinned
provider, `locals` tags everywhere, described and typed variables, a sensitive
password variable, an encrypted volume with a KMS key.

- `ARCH-SPOF-001` — `aws_db_instance.primary` has `multi_az = false` and holds the
  customer orders database. `var.environment` is threaded into the name and tags and
  the backend key is `env/prod/`, so exclusion 11 does not apply: this is not dev, and
  it is not a read replica.
- `TF-RES-002` — the same 500GB instance has no `lifecycle` block, so a change to any
  force-new attribute destroys it without the plan being stopped. Exclusion 9 needs
  the data named as disposable; a customer orders database is the opposite.
- `SEC-NET-003` — three subnets declared from one `count`, identical but for CIDR and
  AZ, with no public/private/data separation and nothing to distinguish tiers. The EKS
  node group then sits across all three.
- `COST-K8S-002` — the node group is `ON_DEMAND` only, with `desired = min = max = 6`
  on `m7i.2xlarge`. Nothing marks the workload as interruption-intolerant: no taint,
  no name suggesting stateful work, and six nodes rather than one, so exclusion 12
  does not rescue it.

Must NOT fire: `TF-VAR-001` (password comes from a variable), `TF-VAR-002` (marked
sensitive), `TF-VAR-003` (all described and typed), `TF-VAR-004` (no hardcoded
region, account, or env literal), `TF-STATE-001`/`002` (backend with locking),
`TF-PROV-001`/`002`, `TF-RES-001` (four required tags), `TF-QUAL-001` (`locals`
used), `SEC-PUB-001` (no bucket here), `TF-OUT-001` (output described).

`TF-OUT-002` must also stay silent: an endpoint is a hostname, not a credential.
