# Force-replacement attributes

Load this when a plan shows a replace and you need to say whether it was avoidable.
`change.replace_paths` tells you *which* attribute forced it; this tells you whether
the provider had any choice.

Three categories, and the recommendation differs for each:

- **Immutable in the AWS API.** The provider cannot update in place because AWS has no
  such call. Replacement is the only path; the question is how to sequence it.
- **Immutable in the provider only.** The API supports a modify call but the provider
  models the attribute as force-new. Sometimes a newer provider version fixes this,
  which is worth checking before scheduling downtime.
- **Avoidable.** The value changed for a reason that can be reverted, or a `moved`
  block or `create_before_destroy` turns the replacement into a non-event.

## Databases and stateful stores

| Resource | Force-new attributes | Notes |
|---|---|---|
| `aws_db_instance` | `availability_zone`, `engine`, `db_name`, `identifier`, `snapshot_identifier`, `character_set_name`, `timezone` | `instance_class`, `allocated_storage`, `engine_version`, and `multi_az` are all in-place. If the plan replaces for one of those, read the diff again: something else changed. |
| `aws_rds_cluster` | `engine`, `database_name`, `cluster_identifier`, `snapshot_identifier`, `master_username`, `global_cluster_identifier` | `master_password` is in-place. A replace attributed to credentials usually means `master_username` moved. |
| `aws_rds_cluster_instance` | `identifier`, `engine`, `cluster_identifier` | Replacing one reader is usually safe; replacing the writer is a failover. |
| `aws_dynamodb_table` | `name`, `hash_key`, `range_key`, `billing_mode` in some transitions, LSI changes | GSIs can be added and removed in place; local secondary indexes cannot. Table replacement is total data loss unless PITR is on. |
| `aws_elasticache_cluster` | `engine`, `node_type` on some engines, `subnet_group_name`, `cluster_id` | Cache loss is usually survivable. Confirm the app treats a cold cache as a degradation rather than an error. |
| `aws_elasticache_replication_group` | `replication_group_id`, `at_rest_encryption_enabled`, `transit_encryption_enabled` on older engine versions | Enabling encryption on an existing group is the classic unavoidable replacement. Engine 7.x onward supports in-place transit encryption. |
| `aws_efs_file_system` | `creation_token`, `encrypted`, `kms_key_id`, `performance_mode` | `throughput_mode` is in-place. Replacement orphans the data unless a backup policy exists. |
| `aws_ebs_volume` | `availability_zone`, `snapshot_id`, `encrypted`, `kms_key_id` | `size`, `type`, and `iops` are in-place (this is what makes gp2 to gp3 an online change). An az move is a snapshot-and-restore, not an update. |
| `aws_s3_bucket` | `bucket`, `bucket_prefix` | A rename is a new bucket. Objects do not follow. |
| `aws_opensearch_domain` | `domain_name`, some `vpc_options` changes, `encrypt_at_rest` enabling | Blue-green internally for many changes, which looks like a long update rather than a replace. |

## Compute and networking

| Resource | Force-new attributes | Notes |
|---|---|---|
| `aws_instance` | `ami`, `availability_zone`, `subnet_id`, `user_data` (unless `user_data_replace_on_change = false`), `instance_type` for some virtualization changes, `placement_group` | `user_data` is the one that surprises people. Setting `user_data_replace_on_change = false` makes edits in-place and applies on next boot. |
| `aws_launch_template` | nothing, it versions | Changes create a new version. The replacement risk moves to whatever references it. |
| `aws_eks_cluster` | `name`, `role_arn`, `vpc_config.subnet_ids` removal, `encryption_config` | Adding subnets is in-place; removing them is not. Cluster replacement means every workload is recreated. |
| `aws_eks_node_group` | `node_group_name`, `subnet_ids`, `capacity_type`, `ami_type`, `disk_size` when not using a launch template | Use a launch template and these become version bumps rather than replacements. |
| `aws_ecs_service` | `name`, `cluster`, `launch_type`, `task_definition` family change | `desired_count` and task definition revisions are in-place, which is why most ECS plans are boring. |
| `aws_subnet` | `vpc_id`, `availability_zone`, `cidr_block` | Subnet replacement cascades into everything with an ENI in it. |
| `aws_vpc` | `cidr_block`, `instance_tenancy` in some transitions | Effectively a rebuild of the environment. |
| `aws_security_group` | `name` (use `name_prefix`), `vpc_id`, `description` | The `description` one is the notorious case: a typo fix in a description replaces the group, and dependent rules churn with it. |
| `aws_lb` | `name`, `internal`, `load_balancer_type`, `subnets` for NLBs | ALB subnets are in-place; NLB subnets are not. A replacement changes the DNS name. |
| `aws_lb_target_group` | `name`, `port`, `protocol`, `target_type`, `vpc_id` | Use `name_prefix` with `create_before_destroy` so listener rules can move over. |
| `aws_nat_gateway` | `subnet_id`, `allocation_id`, `connectivity_type` | New public IP unless the EIP is preserved, which breaks anything allowlisting it. |

## IAM, KMS, secrets

| Resource | Force-new attributes | Notes |
|---|---|---|
| `aws_iam_role` | `name` (use `name_prefix`), `path` | Anything holding the role ARN needs updating. |
| `aws_iam_user` | `name`, `path` | Access keys do not survive. |
| `aws_kms_key` | `customer_master_key_spec`, `key_usage`, `deletion_window_in_days` is in-place | A replaced key cannot decrypt data encrypted by the old one. This is permanent data loss wearing an ordinary-looking diff. |
| `aws_secretsmanager_secret` | `name`, `force_overwrite_replica_secret` transitions | Deletion is soft, with a recovery window, so this is recoverable if caught quickly. |
| `aws_acm_certificate` | `domain_name`, `subject_alternative_names`, `validation_method` | Replacement requires re-validation. With DNS validation and the records in Terraform this is usually seamless; with email validation it is not. |

## Reducing a replacement to a non-event

**`create_before_destroy`.** Turns `["delete","create"]` into `["create","delete"]`, so
the new resource exists before the old one goes. Requires the resource to tolerate a
name collision, which is why `name_prefix` and `create_before_destroy` travel
together:

```hcl
resource "aws_security_group" "api" {
  name_prefix = "api-"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}
```

Useless for anything holding data. A database cannot be created beside itself.

**`prevent_destroy`.** Turns an accidental replacement into a failed plan, which is
the outcome you want at 17:00 on a Friday:

```hcl
lifecycle {
  prevent_destroy = true
}
```

Note it blocks the plan rather than warning, so a deliberate migration means removing
it in one commit and applying in the next. That friction is the feature.

**`ignore_changes`.** For attributes something outside Terraform owns:

```hcl
lifecycle {
  ignore_changes = [desired_count, tags["LastScaledBy"]]
}
```

Do not reach for this to hide a replacement you do not understand. It hides the
symptom and the cause together.

**`moved` blocks.** When the replacement is really a rename, no infrastructure needs
to change at all:

```hcl
moved {
  from = aws_db_instance.database
  to   = aws_db_instance.main
}
```

A plan full of paired create-and-destroy entries for resources with identical
attributes is almost always a missing `moved` block, and is the one case where a
32-resource plan is genuinely a no-op.

## When the attribute is not the real cause

Two cases worth naming before recommending anything:

**A module default moved.** The user changed nothing; a module version bump changed a
default that happens to be force-new. `terraform plan` attributes it to the attribute,
not the version. Check whether the module version also changed in the same diff, and
if so say that the version bump is the cause and the attribute is the mechanism.

**A provider upgrade changed the schema.** Providers occasionally move an attribute
between in-place and force-new, in both directions. If the plan replaces something on
a major provider bump and the attribute value is unchanged, the provider is the cause.
Say so, and check the provider changelog rather than proposing a migration.
