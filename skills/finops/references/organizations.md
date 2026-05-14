# AWS Organizations & Multi-Account FinOps Reference

Multi-account structure, consolidated billing benefits, RI/SP sharing, SCP guardrails, account hygiene at scale, and budget kill-switches.

## Why Multi-Account

A landing-zone-style multi-account setup (Control Tower, Landing Zone Accelerator, or hand-rolled Organizations) gives you:

- **Hard cost attribution** — accounts are the only AWS construct that *cannot* leak between teams. Tags can be missed; account boundaries can't.
- **Blast-radius containment** — runaway spend, compromised credentials, or a bad Terraform apply stops at the account boundary.
- **Per-environment quotas** — lower service quotas in non-prod accounts as a soft cost cap.
- **Targeted SCPs** — apply restrictive policies (region lockdown, instance-type allowlist) per OU without touching prod.
- **Clean RI/SP sharing** — consolidated billing automatically pools commitments across accounts.

## Recommended OU Structure (FinOps Lens)

```
Root
├── Security             (audit, log archive)
├── Infrastructure       (network, shared services, transit)
├── Workloads
│   ├── Production       (one account per major workload or business unit)
│   ├── Non-Production   (staging, QA)
│   └── Development      (per-team accounts)
├── Sandbox              (per-engineer or per-team experimentation)
└── Suspended            (decommissioned accounts before deletion)
```

The cost-relevant patterns: prod isolated, sandbox capped hard, dev/test scheduled aggressively, network spend pooled in Infrastructure for visibility.

## Consolidated Billing — Defaults That Matter

Enabled the moment Organizations is set up. Two cost mechanics:

1. **Pooled volume tiers** — S3, data transfer, CloudFront usage tiers across the org sum together → cheaper per-GB tiers reached faster.
2. **Pooled RI/SP application** — commitments in any account apply to *any* eligible usage in any account in the org (subject to sharing settings).

### RI/SP Sharing — Verify Settings

In the **Management account → Billing → Billing preferences**:

- **RI discount sharing: ON** (default ON) — RIs purchased in one account apply to other accounts.
- **Savings Plans discount sharing: ON** (default ON) — SPs apply across accounts.

You can opt individual accounts in or out. **Common pattern:** centralize SP/RI purchases in a single "FinOps" or management account, with sharing ON for all accounts. Or buy in the account that owns the workload, with sharing ON.

**Watch out:** if sharing is OFF for an account, its on-demand usage will not be discounted by org-level commitments and its purchased commitments stay local. Check before buying.

## SCP Guardrails for Cost

SCPs (Service Control Policies) are deny rules at the OU/account level. They override IAM. Use sparingly — they can also lock you out.

### SCP 1 — Region Lockdown

Restrict resource creation to approved regions. Eliminates accidental spend in regions no one is monitoring (`ap-east-1`, `me-south-1`, etc.).

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyAllOutsideApprovedRegions",
    "Effect": "Deny",
    "NotAction": [
      "iam:*", "organizations:*", "route53:*", "cloudfront:*",
      "waf:*", "wafv2:*", "support:*", "trustedadvisor:*",
      "globalaccelerator:*", "budgets:*", "ce:*", "sts:*",
      "a4b:*", "artifact:*", "chime:*", "health:*"
    ],
    "Resource": "*",
    "Condition": {
      "StringNotEquals": {
        "aws:RequestedRegion": ["us-east-1", "us-west-2"]
      }
    }
  }]
}
```

The `NotAction` list excludes global services (which always live in `us-east-1`). Adjust to the regions and global services you actually use.

### SCP 2 — Instance Type Allowlist (Sandbox)

Prevent expensive instance launches in sandbox accounts. Stops "I'll just spin up a `p4d.24xlarge` for an hour" mistakes.

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyExpensiveInstanceTypes",
    "Effect": "Deny",
    "Action": ["ec2:RunInstances"],
    "Resource": "arn:aws:ec2:*:*:instance/*",
    "Condition": {
      "StringNotLike": {
        "ec2:InstanceType": [
          "t3.*", "t4g.*",
          "m5.large", "m5.xlarge", "m6i.large", "m6i.xlarge",
          "m6g.large", "m6g.xlarge"
        ]
      }
    }
  }]
}
```

### SCP 3 — Require Tags on Create

Block resource creation without required cost-allocation tags. Phase in carefully — initial rollout will break things.

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyEC2WithoutOwnerTag",
    "Effect": "Deny",
    "Action": ["ec2:RunInstances"],
    "Resource": ["arn:aws:ec2:*:*:instance/*", "arn:aws:ec2:*:*:volume/*"],
    "Condition": {
      "Null": { "aws:RequestTag/Owner": "true" }
    }
  }, {
    "Sid": "DenyTagDeletion",
    "Effect": "Deny",
    "Action": ["ec2:DeleteTags"],
    "Resource": "*",
    "Condition": {
      "ForAnyValue:StringEquals": {
        "aws:TagKeys": ["Owner", "CostCenter", "Environment"]
      }
    }
  }]
}
```

**Phased rollout:** start with `aws:RequestTag` only on EC2 + RDS in dev/sandbox OUs → expand resources → expand to all OUs → add tag-deletion protection.

### SCP 4 — Deny Expensive "Easy to Forget" Resources in Sandbox

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyExpensiveSandboxResources",
    "Effect": "Deny",
    "Action": [
      "directconnect:*",
      "fsx:CreateFileSystem",
      "redshift:CreateCluster",
      "rds:PurchaseReservedDBInstancesOffering",
      "ec2:PurchaseReservedInstancesOffering",
      "savingsplans:CreateSavingsPlan"
    ],
    "Resource": "*"
  }]
}
```

Prevents accidental commitment purchases or large-spend resources in the wrong account.

### SCP 5 — Prevent Public S3 in All Accounts

Indirect cost protection — public S3 buckets are how surprise data-egress bills happen.

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyPublicS3",
    "Effect": "Deny",
    "Action": [
      "s3:PutBucketPublicAccessBlock"
    ],
    "Resource": "*",
    "Condition": {
      "Bool": {
        "s3:PublicAccessBlockConfiguration": "false"
      }
    }
  }]
}
```

Combine with the account-level S3 Block Public Access setting enabled by default.

## Tag Policies

Tag Policies (Organizations feature) **standardize tag values**, where SCPs only enforce tag presence. Apply at the OU level.

```json
{
  "tags": {
    "Environment": {
      "tag_key": { "@@assign": "Environment" },
      "tag_value": { "@@assign": ["prod", "staging", "dev", "sandbox"] },
      "enforced_for": { "@@assign": ["ec2:instance", "rds:db", "s3:bucket"] }
    },
    "CostCenter": {
      "tag_key": { "@@assign": "CostCenter" },
      "tag_value": { "@@assign": ["CC-100", "CC-200", "CC-300"] },
      "enforced_for": { "@@assign": ["ec2:instance", "rds:db"] }
    }
  }
}
```

Without a Tag Policy, you'll get `Environment=prod`, `Environment=Production`, `Environment=PROD` across the org and your cost reports will be a mess.

## Budget Kill-Switches (Sandbox)

Budget Actions automate response when a budget is breached. Pair with sandbox accounts to enforce hard caps.

### Pattern: Stop All EC2 + RDS at 100% of Sandbox Budget

1. **Budget:** monthly $500 on a sandbox account, alert at 80% / 100%.
2. **Budget Action @ 100%:** apply an SCP that denies `ec2:RunInstances`, `ec2:StartInstances`, `rds:CreateDBInstance`, `rds:StartDBInstance`. Existing resources keep running but nothing new launches.
3. **Or harder:** Budget Action invokes a Lambda that stops all EC2 instances and stops all RDS instances in the account.

**Don't do this on prod accounts.** Budget Actions can disrupt service. Reserved for sandboxes and per-engineer dev accounts.

## Service Quotas as Soft Cost Caps

Lower default Service Quotas in non-prod accounts. Even without SCPs, this caps blast radius.

| Quota | Default | Recommended sandbox value |
|---|---|---|
| Running On-Demand vCPUs (Standard) | 1152 | 64 |
| Running On-Demand vCPUs (G/VT) | 0 (request needed) | 0 |
| Running On-Demand vCPUs (P) | 0 | 0 |
| RDS Max DB instances | 40 | 10 |
| EBS gp3 storage (TiB) | 50 | 5 |
| NAT Gateways per AZ | 5 | 1 |
| EIPs per region | 5 | 2 |

Adjust to your actual needs. Quotas are per-region.

## Cost Allocation in a Multi-Account Org

In the **management account → Billing → Cost Allocation Tags**:

1. **Activate AWS-generated cost allocation tags** (e.g., `aws:createdBy`).
2. **Activate user-defined cost allocation tags** for `Owner`, `CostCenter`, `Environment`, `Project`.
3. Cost Explorer + CUR + Budgets can now group by these tags **across all accounts**.

**Backfill:** new tag activations only apply to *future* usage. Activate tags before you actually need to report on them. There is no historical recompute.

## CUR at the Org Level

Set up the **Cost & Usage Report in the management account** with:
- Include resource IDs ✓
- Include resource tags ✓
- Refresh automatically ✓
- Format: Parquet, GZIP

This single CUR contains line items for **every account in the org**. Don't set up per-account CURs — duplicate data + Athena query complexity.

Pair with **CUDOS / CID dashboards** (QuickSight) for org-wide visibility. See `tooling.md`.

## Cost Anomaly Detection at Org Level

Enable in the management account with monitors:
- **One per linked account** — catches per-account spend anomalies.
- **One per AWS service category** — catches a service spiking across the org (e.g., NAT Gateway runaway).

Subscribe to SNS → Slack via Lambda. Free; the noise reduction from running it at the org level (vs per-account) is significant.

## Account Lifecycle Hygiene

- **Decommissioning:** when retiring a workload, *close* the account (don't just leave it empty). Open accounts cost nothing themselves but accumulate forgotten resources. Move to "Suspended" OU first, audit for 90 days, then close.
- **Account close gotchas:** S3 buckets must be emptied; certain resources block account closure. Run a cleanup pass.
- **Compute Optimizer + Trusted Advisor + Cost Anomaly Detection:** enable across the *entire* org via management account, not per-account.
- **Member account root access:** use IAM Identity Center; root credentials should be locked away with hardware MFA. Don't use root for anything routine.

## A Reasonable Multi-Account FinOps Stack

For a 20-50 account org:

1. **Landing zone:** Control Tower or LZA with the OU structure above.
2. **SCPs:** region lockdown (all OUs), tag-presence (Workloads OU), instance-type allowlist (Sandbox OU), public-S3 deny (all OUs).
3. **Tag Policies:** `Environment`, `CostCenter`, `Owner` enforced on EC2/RDS/S3.
4. **Budget kill-switches:** $500-$2000/month per sandbox account with auto-stop.
5. **Service Quotas:** lowered in non-prod via Quota Request Templates (org feature).
6. **Org-level CUR + CUDOS dashboard** in a dedicated billing account.
7. **Compute Optimizer + Cost Anomaly Detection + Trusted Advisor** enabled org-wide.
8. **Centralized commitment purchases** in management account with sharing ON.
9. **Quarterly FinOps review** across the org using CUDOS + `scripts/reservation-coverage.sh`.
