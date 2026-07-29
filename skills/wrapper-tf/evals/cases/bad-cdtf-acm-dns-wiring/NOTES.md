# bad-cdtf-acm-dns-wiring

The upstream-module gotchas, which are the findings a generic Terraform linter
cannot produce because none of this is invalid HCL. It plans, it applies, and it is
wrong in ways only someone who has debugged this module pair would recognise.

- `CDTF-MOD-003` — `module "acm"` hardcodes `zone_id = "Z04SBGH1OQ8YKPGXPRJ7"`
  instead of referencing `module.dns.zone_id`. It works until the zone is recreated,
  then validation silently targets a zone that no longer exists.
- `CDTF-MOD-004` — `subject_alternative_names` is passed to `module "dns"`. SANs
  belong on the certificate, not the hosted zone, so the wildcard is quietly
  dropped and nobody notices until a subdomain serves the wrong cert.
- `CDTF-MOD-006` — `enable_dns_validation = false` with no explanatory comment.
  ADVISORY, and per exclusion 2 this is the *only* finding it produces: it must not
  also be escalated into a separate blocking finding.
- `CDTF-MOD-007` — `_modules/edge/` has `main.tf` and `variables.tf` but no
  `outputs.tf`, so nothing downstream can consume the zone id or certificate ARN,
  which is how the hardcoded `zone_id` above came to exist in the first place. This
  is why the case is a directory rather than a file: the finding is a missing file,
  and no single-file fixture can express it.
- `CDTF-MOD-008` — `variable "certificate_transparency_logging"` is declared, typed,
  described, defaulted, and never passed into any module call. Dead input that reads
  as configuration.
- `CDTF-WRAP-003` — `locals.name_prefix` is hand-assembled from `client_name` and
  `environment` instead of taking `module.labels.name_prefix`.

`CDTF-WRAP-002` must NOT fire: `module "labels"` is present and its `tags` output is
consumed. The defect is that the module ignores the label module's *prefix*, which is
`CDTF-WRAP-003`. Reporting both would double-count.

`CDTF-NAME-002` must NOT fire either: both module calls pass `label_order = ["name"]`.
Versions are pinned on both, so `TF-MOD-002` stays silent, and every variable has a
description and type, so `TF-VAR-003` does too.
