# Reading `terraform show -json`

Load this when you need a field you are not certain about, or when the human-readable
plan and the JSON seem to disagree.

Produced by:

```bash
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
```

`terraform show -json` with no plan file argument prints **state**, not a plan, and has
no `resource_changes` key at all. If the file you were handed has `values` at the top
level and no `resource_changes`, that is what happened: ask for the plan.

## Top-level keys

| Key | What it carries | Use |
|---|---|---|
| `format_version` | Plan format, currently `1.2` | Sanity check. Fields below have moved between 0.x and 1.x. |
| `terraform_version` | CLI that produced it | Relevant when a field is missing that you expect. |
| `resource_changes` | The array every finding comes from | The plan proper. |
| `resource_drift` | Changes detected during refresh, separate from planned changes | The precise source for `TF-PLAN-003`. Present from 1.1 onward. |
| `configuration` | Parsed config: providers, module calls, expressions | Version constraints for `TF-PLAN-005`. |
| `prior_state` | State as refreshed, before changes | Module layout, and what exists today. |
| `planned_values` | State as it will be after apply | Useful for counting the end result rather than the delta. |
| `output_changes` | Changes to root outputs, with sensitivity | A secret newly exposed through an output shows here. |
| `variables` | Root variable values as resolved | Where the target environment is often provable. |
| `checks` | Results of `check` blocks and postconditions | A failing precondition is worth reporting even when it is not in the catalog. |
| `errored` | `true` if the plan itself failed | Never review a plan with this set. Say the plan failed. |

There is no top-level `backend` key in real Terraform output. Backend configuration
lives under `configuration.root_module` or is absent entirely, so infer the target
environment from `variables`, resource tags, or the workspace instead, and say which
evidence you used.

## Inside `resource_changes[]`

```json
{
  "address": "module.db.aws_db_instance.main",
  "module_address": "module.db",
  "mode": "managed",
  "type": "aws_db_instance",
  "name": "main",
  "index": 0,
  "provider_name": "registry.terraform.io/hashicorp/aws",
  "action_reason": "replace_because_cannot_update",
  "change": {
    "actions": ["delete", "create"],
    "before": { "...": "..." },
    "after": { "...": "..." },
    "after_unknown": { "endpoint": true },
    "before_sensitive": { "password": true },
    "after_sensitive": { "password": true },
    "replace_paths": [["availability_zone"]],
    "importing": null
  }
}
```

**`address` vs `module_address`.** Always report `address`: it is what a reader can
paste into `terraform state show`. `module_address` is useful for grouping when
counting blast radius across modules.

**`mode`.** `managed` or `data`. Data sources appear in `resource_changes` with
`["read"]` actions and are never findings. Filter them out before counting.

**`change.actions`** is the whole classification:

| Value | Meaning |
|---|---|
| `["no-op"]` | Nothing planned. Check `resource_drift` separately. |
| `["create"]` | New. |
| `["read"]` | Data source read, ignore. |
| `["update"]` | In place. |
| `["delete"]` | Destroy. |
| `["delete","create"]` | Replace, destroy first. |
| `["create","delete"]` | Replace with `create_before_destroy`. |
| `["forget"]` | Removed from state, left alive (a `removed` block). Not a destroy, and worth saying so explicitly. |

**`action_reason`** is the honest answer to "why", when present:
`replace_because_cannot_update`, `replace_because_tainted`,
`replace_by_request` (someone passed `-replace=`),
`delete_because_no_resource_config`, `delete_because_no_module`,
`delete_because_count_index`, `delete_because_each_key`,
`delete_because_wrong_repetition`, `read_because_config_unknown`.

`replace_by_request` deserves calling out in a review: a human explicitly asked for
this replacement, which is a very different finding from Terraform deciding on one.
`delete_because_no_resource_config` on something data-bearing means the resource block
was removed from code, which is usually not what the author intended.

**`replace_paths`** is an array of attribute paths, each itself an array of steps:
`[["availability_zone"]]` is `availability_zone`, and
`[["vpc_config", 0, "subnet_ids"]]` is `vpc_config[0].subnet_ids`. Absent on non-replace
actions. If it is absent on a replace, `action_reason` carries the reason instead
(tainted, or requested).

**`before` and `after`.** `before` is null on create; `after` is null on delete. Diff
only the paths in `replace_paths` when explaining a replacement, because diffing
everything buries the cause in noise.

**`after_unknown`.** Values Terraform cannot know until apply, as a mirror-shaped
object of `true` flags. An attribute being unknown is not a change and not a finding.
This is the field that makes plans look larger than they are.

**`before_sensitive` and `after_sensitive`.** Mirror-shaped objects of booleans, marking
which values are sensitive. This is the field `TF-PLAN-002` turns on:

- `after_sensitive.password === true` means the value is redacted in output. Not a
  finding, however secret-shaped the value looks.
- A credential-shaped value with `after_sensitive` false or absent for that path **is**
  the finding.

Note that these can also be `true` or `false` as whole booleans rather than objects when
the entire value is sensitive, so handle both shapes.

## Drift, precisely

`resource_drift` is the right source for `TF-PLAN-003`, and it is structured exactly
like `resource_changes`:

```json
"resource_drift": [
  {
    "address": "aws_security_group.api",
    "change": {
      "actions": ["update"],
      "before": { "ingress": [ { "from_port": 8080, "cidr_blocks": ["10.0.0.0/8"] } ] },
      "after":  { "ingress": [] }
    }
  }
]
```

Drift means state and reality diverged, discovered during refresh, with no code change
asking for it. Someone changed it outside Terraform.

If `resource_drift` is absent (older Terraform, or `-refresh=false`), fall back to
`no-op` entries whose `before` and `after` differ, and say that is what you did. Do not
present an inference from `no-op` diffs as confidently as a `resource_drift` entry.

Provider normalization is the false positive here: an ARN filling in, `tags_all`
merging provider defaults, set reordering, a timestamp, a version string the provider
rewrites. Exclusion 3 exists for exactly these.

## Version constraints

For `TF-PLAN-005`, read `configuration.provider_config`:

```json
"configuration": {
  "provider_config": {
    "aws": { "name": "aws", "version_constraint": "~> 6.0" }
  }
}
```

The plan carries the **current** constraint only. It does not record the previous one,
so a bundled version bump is established by comparing against the diff of
`versions.tf` or the lock file, not from the plan alone. Say which source you used.

`.terraform.lock.hcl` is the stronger evidence: it records exact resolved versions, and
its diff shows a bump unambiguously.

## Counting blast radius honestly

For `TF-PLAN-004`, count entries where `mode == "managed"` and `actions` is not
`["no-op"]` and not `["read"]`. Then check whether they span environments, by grouping
on `module_address` prefix, on an `Environment` tag in `after`, or on the workspace.

A count alone is weak. Thirty changes in one module during a first apply is normal; six
changes split across a dev module and a prod module in one state file is the finding
even though the number is smaller.

## Working from text output instead

If you only have `terraform plan` console text, these are gone: `replace_paths`, the
sensitivity markers, `action_reason`, and `resource_drift` as a distinct section. You
can still identify replacements from `# ... must be replaced` and the `-/+` markers, and
Terraform prints `# forces replacement` inline next to the attribute, which recovers
most of `replace_paths`.

Say plainly which fields you could not see. Sensitivity in particular cannot be
recovered from text, so `TF-PLAN-002` becomes a guess, and a guess about whether a
password is exposed is worth less than asking for the JSON.
