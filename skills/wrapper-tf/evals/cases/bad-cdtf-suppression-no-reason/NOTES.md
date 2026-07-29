# bad-cdtf-suppression-no-reason

`wrapper-tf:ignore SEC-NET-002` with no `-- reason`, above
`publicly_accessible = true` on an Aurora cluster.

Note the token here is `wrapper-tf:ignore`, not `wrapper-tf-skill:ignore`. This
skill's convention differs from the others, which is itself worth pinning in a
fixture.

Both fire: `META-SUP-001` for the unreasoned suppression and `SEC-NET-002` for the
publicly reachable database, because a suppression missing its reason does not
suppress anything. This is the most consequential silencing available in this
catalog: a one-line unjustified comment putting a production database on the
public internet.

This case also gives `SEC-NET-002` its first fixture in this suite.

The wrapper pattern itself is deliberately correct so no `CDTF-*` rule fires: the
module wraps a `clouddrove/*/aws` source, both the module and the labels module are
version-pinned, `module "labels"` is present with a `label_order`, and the resource
name derives from `module.labels.id`. `SEC-ENC-001` must NOT fire either
(`storage_encrypted = true` with a KMS key), nor `OBS-MON-001`
(`performance_insights_enabled = true`).
