# AWS Waste Reference

Idle resources, dev/test scheduling, snapshot/AMI cleanup, untagged spend, and account hygiene.

## The Idle Resource Catalog

These appear in nearly every AWS account. Run `scripts/find-idle-resources.sh` for an automated sweep.

| Resource | Why it costs money | How to detect |
|---|---|---|
| **Unattached EBS volumes** | EBS bills on provisioned size, attached or not | `aws ec2 describe-volumes --filters Name=status,Values=available` |
| **Stopped EC2 instances** | EBS still billed; EIPs may also be billed | `aws ec2 describe-instances --filters Name=instance-state-name,Values=stopped` |
| **Unused Elastic IPs** | Unattached EIPs cost ~$3.60/month each (and now associated EIPs are billed too as of Feb 2024) | `aws ec2 describe-addresses --query 'Addresses[?AssociationId==null]'` |
| **Idle ELBs** | Hourly minimum even with zero traffic (~$16-22/month) | CloudWatch `RequestCount`/`ActiveFlowCount` near zero for 14+ days |
| **Old snapshots** | Bill per GB stored, accumulate forever | `aws ec2 describe-snapshots --owner-ids self` filtered by `StartTime` |
| **Deregistered AMI underlying snapshots** | Deregistering an AMI does not delete its snapshots | Cross-reference EBS snapshots with no parent AMI |
| **Unused ENIs** | Detached ENIs left from deleted resources | `aws ec2 describe-network-interfaces --filters Name=status,Values=available` |
| **Unused Route 53 zones** | $0.50/month per hosted zone | `aws route53 list-hosted-zones` and check for usage |
| **Old CloudWatch Log Groups** | Storage cost accumulates; default retention is "never expire" | List groups without retention; set retention policies |
| **Idle NAT Gateways** | Hourly fixed cost (~$33/month each) even with zero traffic | CloudWatch `BytesOutToDestination` near zero |
| **Idle RDS instances** | Often used for testing then forgotten | `DatabaseConnections` near zero for weeks |
| **Old DB snapshots** | Can be huge and unmonitored | `aws rds describe-db-snapshots` filtered by age |
| **Empty S3 buckets with versioning** | Old versions and delete markers still bill | S3 Storage Lens "non-current versions" metric |
| **Provisioned IOPS on idle io1/io2** | Extra IOPS billed regardless of use | EBS read/write ops near zero |

## Dev/Test Scheduling

Non-prod stopped 12 hours/day on weekdays + all weekend ≈ **128 hours running per 168-hour week ≈ 76% on**. Stop those = ~24% saving on those workloads. Aggressive 9am-6pm M-F = ~46 of 168 hours = ~73% saving.

### Implementation Options

- **AWS Instance Scheduler** — official solution; CloudFormation template; tag-driven.
- **EventBridge + Lambda** — write a tiny tag-driven start/stop. Works for EC2, RDS, ECS services, ASG desired counts.
- **EKS Karpenter** — scales worker nodes to 0 automatically when no workload pods are scheduled.
- **DIY tag convention:** `Schedule=mon-fri-9-18` consumed by a Lambda; `Schedule=24x7` opt-out for things that must stay up.

### Gotchas

- **RDS auto-restart after 7 days.** RDS instances stopped manually auto-restart in 7 days (data integrity reason). For long pauses, snapshot + delete instead.
- **Aurora Serverless v2 already scales to a min ACU**, not zero. v1 could pause; v2 cannot. Re-evaluate if your dev DB is a candidate for v2 with min 0.5 ACU.
- **Spot interruption.** Don't schedule scale-down on Spot ASGs; let Spot dynamics handle it.

## Snapshot and AMI Cleanup

Snapshot sprawl is one of the most common silent cost growths.

### Plan

1. **Inventory:** list all snapshots, age, size.
2. **Categorize:**
   - Snapshots tied to a current AMI/volume — keep per retention policy.
   - Orphan snapshots (no parent volume / AMI deregistered) — candidates for deletion.
   - Snapshots older than your stated retention (e.g., 90 days) — review and delete.
3. **Implement DLM** going forward to prevent recurrence.
4. **For AMIs:** deregister old AMIs **and** delete the underlying snapshots in the same workflow. Simply deregistering does not free storage.

### Automation

- **AWS Backup** with a lifecycle policy is the cleanest modern approach for snapshots, RDS backups, EFS, DynamoDB, etc. Centralized retention across services.
- **Recycle Bin (EBS)** — soft-delete protection with configurable retention. Enable to make snapshot cleanup safer.

## Untagged Spend Strategy

You can't optimize what you can't attribute.

### Required Tags (recommended baseline)

- `Owner` (team or person)
- `Environment` (prod / staging / dev / sandbox)
- `CostCenter` or `Project`
- `Schedule` (for off-hours scheduling)

### Drive Compliance

1. **Enable cost allocation tags** in Billing console for the chosen tag keys.
2. **Run `scripts/untagged-spend.sh`** to find offenders.
3. **AWS Config rules** to detect missing tags (`required-tags`).
4. **SCP (Service Control Policy)** at the org level to deny resource creation without required tags — strong but disruptive; phase in.
5. **Tag Policies** in AWS Organizations to enforce tag values match expected casing/format.

### Pragmatic Path

- Start with cost-allocation tags on top 80% of spend (EC2, RDS, S3 buckets, ELBs).
- Backfill tags via Resource Groups Tag Editor or a one-time script.
- Add Config rules + dashboards.
- Move to SCP enforcement only once compliance is >90% — earlier and you'll block legitimate work.

## Account Hygiene

- **Multi-account structure with AWS Organizations.** Per-team or per-environment OUs make cost attribution natural and policy enforcement easier.
- **Sandbox accounts with hard budget kill-switches.** Use Budget Actions to stop EC2/RDS or apply restrictive SCPs when a sandbox account exceeds its monthly budget.
- **Quotas as guardrails.** Lower service quotas in non-prod accounts to limit blast radius (e.g., max 50 vCPUs for EC2 in dev).
- **AWS Compute Optimizer + Trusted Advisor** enabled on all accounts.
- **Cost anomaly detection** (Cost Explorer feature) — free, ML-based, alerts on unusual spend patterns. Enable everywhere.

## Common Cost Surprises (Worth Watching)

- **Inter-region replication** turned on "just in case" — ongoing storage + transfer cost.
- **CloudWatch Logs ingestion** — most expensive part of CloudWatch. Drop log levels, sample, or ship to S3 for retention.
- **VPC Flow Logs to CloudWatch** instead of S3 — S3 is much cheaper.
- **NAT data transfer to AWS services** that have VPC endpoints (S3, DynamoDB, ECR) — pure waste.
- **GuardDuty / Security Hub / Macie** — valuable but pricey at scale; review enabled features and findings retention.
- **Provisioned Concurrency on Lambda** left on after a launch — bills 24/7 even with no requests.
- **Idle Aurora replicas** in non-prod.
- **Unused KMS customer-managed keys** — $1/month each, plus $0.03/10k API requests. Audit and delete.
- **AWS Config** recording all resources in all regions — surprisingly costly. Scope to needed regions and resource types.
