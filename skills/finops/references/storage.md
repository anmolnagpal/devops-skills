# AWS Storage Cost Reference

EBS, EBS snapshots, S3 storage classes, S3 lifecycle, and common storage waste.

## EBS Volume Types — When to Use What

| Type | Use for | Pricing model | Notes |
|---|---|---|---|
| **gp3** | Default for almost everything | Flat $/GB + provisioned IOPS/throughput above baseline | **Replaces gp2 in nearly all cases.** ~20% cheaper, configurable IOPS/throughput independent of size. |
| `gp2` | (legacy) | $/GB; IOPS scales with size | Migrate to gp3. |
| `io2` / `io2 Block Express` | Sustained high IOPS DBs (>16k IOPS) | $/GB + $/IOPS | Expensive. Use only when gp3 ceiling is hit. io2 has 99.999% durability vs gp3's 99.8-99.9%. |
| `st1` | Throughput-optimized HDD (big sequential reads — log processing, big data) | $/GB | Cheap per GB. Bad for random I/O. |
| `sc1` | Cold HDD (rarely accessed) | $/GB | Cheapest EBS. Only for data accessed less than once per day. |

### gp2 → gp3 Migration

**Always do this.** It's an online operation (`aws ec2 modify-volume`) — no downtime, no detach.

- gp3 base: 3000 IOPS + 125 MB/s included with any size.
- gp2: IOPS = 3 × size_GiB, capped at 16,000.
- For volumes ≤ ~1 TiB, gp3 base perf already matches or exceeds what gp2 delivers.
- For larger volumes, you may need to provision extra IOPS/throughput on gp3 — still typically cheaper than gp2.

Run `scripts/ebs-gp2-to-gp3-audit.sh` to estimate savings per volume.

### EBS Sizing Pitfalls

- **Don't confuse provisioned size with usage.** EBS bills on provisioned size, not used. A 1 TB volume that's 10% full bills as 1 TB.
- **Shrinking is painful** — you can't shrink in place; create a new smaller volume and migrate.
- **EBS Multi-Attach (io1/io2):** charged per attached instance.

## EBS Snapshots

Snapshots are incremental but still grow over time. Common waste:

- **Old snapshots** of deleted EC2 / RDS / volumes that no one cleaned up.
- **AMI snapshots** kept indefinitely after AMI deregistration. The AMI deregister doesn't delete underlying snapshots — must be done explicitly.
- **EBS-direct-API "fast snapshot restore"** — billed per snapshot per AZ enabled. Disable if not needed.

### Use Data Lifecycle Manager (DLM)

DLM is free and handles snapshot policies declaratively:

- Daily snapshot, retain N days
- Cross-region copy (note: cross-region copy + storage costs apply)
- Tag-based selection

Define a default retention policy (e.g., 7 daily + 4 weekly + 3 monthly) and apply via tags.

## S3 Storage Classes

| Class | $/GB-month (US, illustrative) | Retrieval | Min storage duration | Use for |
|---|---|---|---|---|
| Standard | ~$0.023 | instant, free | none | Hot data, < 30 days old |
| Standard-IA | ~$0.0125 | instant, $/GB retrieval | 30 days | Infrequent but instant access (logs accessed monthly) |
| One Zone-IA | ~$0.01 | instant, $/GB retrieval | 30 days | Recreatable secondary copies; single-AZ risk |
| **Intelligent-Tiering** | tiers automatically; small monitoring fee | instant (most tiers) | 30 days | **Default when access pattern is unknown.** |
| Glacier Instant Retrieval | ~$0.004 | instant, $/GB retrieval | 90 days | Rarely accessed but needed instantly |
| Glacier Flexible Retrieval | ~$0.0036 | minutes-hours | 90 days | Backups, compliance archives |
| Glacier Deep Archive | ~$0.00099 | 12 hours | 180 days | Long-term compliance, replace tape |

### Decision Heuristic

```
Object accessed monthly+? → Standard (or Intelligent-Tiering)
Access pattern unknown / mixed? → Intelligent-Tiering (let AWS sort it)
Accessed rarely but must be instant? → Glacier Instant Retrieval
Accessed rarely and minutes-hours OK? → Glacier Flexible Retrieval
Compliance archive, never read? → Glacier Deep Archive
```

### Intelligent-Tiering — The Easy Win

Auto-moves objects between tiers based on access. Small monitoring fee per 1000 objects (skip for < 128 KB objects — they don't tier). For large buckets with mixed access, this is the single highest-leverage S3 lever.

### Lifecycle Rules

Use lifecycle rules for **deterministic** transitions when you know the access pattern:

```
Day 0–30:   Standard
Day 30–90:  Standard-IA
Day 90–365: Glacier Instant Retrieval
Day 365+:   Glacier Deep Archive
Day 7y:     Expire (delete)
```

Apply via S3 console or `aws s3api put-bucket-lifecycle-configuration`.

### Common S3 Waste

1. **Incomplete multipart uploads.** Failed uploads leave orphaned parts that are billed but invisible from `aws s3 ls`. Always set a lifecycle rule:
   ```
   AbortIncompleteMultipartUpload after 7 days
   ```
2. **Old object versions** in versioned buckets. Add lifecycle rule: transition non-current versions to IA/Glacier and expire after N days.
3. **Delete markers** without object versions. Lifecycle rule: `ExpiredObjectDeleteMarker = true`.
4. **Cross-region replication** kept "just in case" — costs storage at destination + cross-region transfer for every PUT. Justify or kill.
5. **Logs going to Standard.** Most log buckets should be Intelligent-Tiering or have a lifecycle rule to IA after 30 days.

### S3 Storage Lens

Free tier covers bucket-level metrics (size, request counts, encryption status). Use it to find your cold buckets and incomplete multipart upload offenders. Advanced metrics (per-prefix) is paid but cheap relative to what it surfaces.

## EFS

- **Bursting** vs **Elastic** vs **Provisioned** throughput modes have very different costs. Default to **Elastic** for unpredictable workloads — pay-per-use.
- **EFS Infrequent Access (IA)** + Lifecycle Management: auto-tiers files not accessed in 30 days. ~85% cheaper for cold data.
- **One Zone storage class** ~47% cheaper than standard, single-AZ.

## FSx

- FSx for Windows / NetApp ONTAP / OpenZFS / Lustre — each has its own storage classes and throughput models. Always check whether your workload needs the specific filesystem; sometimes EBS or EFS suffice at lower cost.
