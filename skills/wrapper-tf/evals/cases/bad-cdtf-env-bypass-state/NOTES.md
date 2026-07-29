# bad-cdtf-env-bypass-state

Repo-shaped, because every finding here is a property of the tree rather than of a
file. `CDTF-STATE-001` in particular cannot be seen in one file at all: two backend
blocks are individually valid and only collide when read together.

- `CDTF-WRAP-001` — `environments/dev/main.tf` calls `clouddrove/aurora/aws`
  directly instead of `../../_modules/aurora`, which is the one rule the whole
  wrapper pattern exists to enforce. Staging and prod do it correctly, so the
  finding must name dev specifically rather than the repo generally.
- `CDTF-STATE-001` — staging and prod share the byte-identical backend key
  `terraform.tfstate` in the same bucket. Applying prod overwrites staging's state.
  Each environment needs a unique key.
- `TF-STATE-001` — `environments/dev/` has no `terraform` block and no backend at
  all, so its state is local to whoever ran it last. Dev is still an environment
  with a backend requirement; the module-only exemption in the rule applies to
  `_modules/`, not to `environments/`.
- `TF-STATE-002` — neither backend declares `dynamodb_table`, so two concurrent
  applies can interleave. Consolidate to one finding naming both files.

The wrapper module under `_modules/aurora/` is deliberately correct so no `CDTF-*`
module rule fires: it calls `module "labels"`, derives its name from
`module.labels.name_prefix`, pins the upstream version, passes `label_order`, ships
all three required files, threads every declared variable into the wrapped call, and
sets `storage_encrypted` with a KMS key plus `performance_insights_enabled`. The
defects are entirely in how the environments consume it and where state lives.
