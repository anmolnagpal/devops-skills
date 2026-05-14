# AWS Reservations Reference

Covers every reservable AWS service: Compute Savings Plans, EC2 Instance Savings Plans, EC2 Standard/Convertible RIs, RDS Reserved Instances, ElastiCache Reserved Nodes, OpenSearch Reserved Instances, Redshift Reserved Nodes, and DynamoDB Reserved Capacity.

> Discount percentages below are illustrative US-region public list-price differentials and shift over time. Always verify current rates with AWS Pricing or Cost Explorer recommendations before purchase.

## Decision Tree: Which Commitment to Buy?

```
What service is the spend on?
│
├─ EC2 / Fargate / Lambda
│  ├─ Mixed across all three or unsure of future instance mix?
│  │  └─→ Compute Savings Plan (most flexible, ~27% off 1yr NU)
│  ├─ Locked to a specific EC2 instance family in one region?
│  │  └─→ EC2 Instance Savings Plan (more savings, ~33% off 1yr NU)
│  └─ Need to reserve specific capacity (rare — usually for capacity, not cost)?
│     └─→ Standard RI (zonal, with capacity reservation)
│
├─ RDS (any engine: MySQL, Postgres, Aurora, Oracle, SQL Server, MariaDB)
│  └─→ RDS Reserved Instance (no SP equivalent exists)
│     ├─ Steady-state production DB? → 3yr All Upfront if cash available, else 1yr No Upfront
│     └─ Match: engine, instance family, region, Multi-AZ vs Single-AZ
│
├─ ElastiCache (Redis or Memcached)
│  └─→ ElastiCache Reserved Node
│     └─ Match: exact node type (no size flex), engine, region
│
├─ OpenSearch
│  └─→ OpenSearch Reserved Instance
│     └─ Match: exact instance type, region. Data nodes only (not master, not UltraWarm)
│
├─ Redshift
│  └─→ Redshift Reserved Node
│     └─ Match: exact node type, region. RA3 only for new purchases.
│
└─ DynamoDB (provisioned mode only)
   └─→ DynamoDB Reserved Capacity
      └─ Reserves RCU and WCU separately; on-demand tables not eligible
```

## Term and Payment — The Math

### Term: 1-year vs 3-year

| Term | Discount vs On-Demand | When to use |
|---|---|---|
| 1-year | ~27-40% (depends on service + payment) | Default. Use unless you are confident the workload won't change for 36 months. |
| 3-year | ~50-65% | Steady-state core production workloads with no architectural change planned. |

**Rule:** the second 1-year purchase is almost always smarter than a 3-year commitment unless the workload is truly stable. Cloud usage shifts faster than you think.

### Payment: No Upfront / Partial Upfront / All Upfront

| Payment | Discount delta | When to use |
|---|---|---|
| No Upfront | baseline | **Default.** Zero capital risk; easy to walk away financially. |
| Partial | +1-2% over NU | Rarely worth it; pick All Upfront or No Upfront. |
| All Upfront | +3-5% over NU | Only if the cash is otherwise idle and you're confident in the workload. |

**Rule:** No Upfront captures ~80% of the savings of All Upfront. The marginal extra discount on All Upfront rarely justifies tying up capital for 12-36 months.

### Coverage and Utilization Targets

- **Coverage** = % of usage covered by a commitment. Aim for **70-80%** of steady-state baseline. Don't try to cover variable/burst usage.
- **Utilization** = % of purchased commitment that's actually used. Aim for **>95%**. Anything lower means you over-bought; AWS bills you for the commitment regardless.

Set AWS Budgets alerts on both. See `tooling.md`.

---

## EC2 / Fargate / Lambda — Savings Plans

Savings Plans are commitments to a $/hour spend (e.g., "$10/hour for 1 year"). AWS auto-applies them to eligible usage to maximize your discount.

### Compute Savings Plan (recommended default)

- **Covers:** EC2 (any instance family, any size, any region, any tenancy, Linux/Windows), Fargate, Lambda.
- **Discount:** ~27% off On-Demand (1yr No Upfront), up to ~54% (3yr All Upfront).
- **Flexibility:** maximum. Can change instance family, region, OS, tenancy, or move between EC2/Fargate/Lambda.
- **When:** default for all general AWS compute reservations.

### EC2 Instance Savings Plan

- **Covers:** specific EC2 instance family (e.g., `m5`) in a specific region. Size-flexible within the family.
- **Discount:** ~33% off (1yr No Upfront), up to ~64% (3yr All Upfront) — more than Compute SP.
- **Flexibility:** within instance family + region only. Cannot move to a different family or region.
- **When:** you have a known, stable instance family in a single region (often the case for steady-state prod).

### Standard Reserved Instance

- **Covers:** specific EC2 instance type, OS, tenancy, region (regional RI) or AZ (zonal RI).
- **Discount:** ~40% (1yr) to ~60% (3yr).
- **Flexibility:** size-flexible within family (regional RI only); zonal RI also reserves capacity.
- **Convertible RI:** can be exchanged for a different instance family/OS/tenancy of equal or greater value. Discount slightly lower than Standard.
- **When:** mostly legacy. Use Compute or EC2 Instance SP instead unless you specifically need a **capacity reservation** (zonal RI) for guaranteed availability in a specific AZ.

### Practical Choice

```
Most accounts → start with Compute Savings Plan covering ~70% of baseline compute spend.
If a large chunk is one EC2 family in one region → layer an EC2 Instance SP on top.
If you need guaranteed AZ capacity → small zonal RI on top of that.
```

Cost Explorer → Recommendations does this math automatically (look-back: 7/30/60 days).

---

## RDS Reserved Instances

**There is no Savings Plan for RDS.** You must use RIs for any RDS commitment.

### Scoping (must match exactly to apply)

| Attribute | Match required |
|---|---|
| Engine | exact (MySQL ≠ MariaDB ≠ Aurora MySQL) |
| Instance family | exact (`db.m5` ≠ `db.r5`) |
| Size flexibility | yes, **within the same family** (1× `db.m5.4xlarge` = 8× `db.m5.large`) |
| Region | regional (applies to any AZ in the region) |
| Multi-AZ | **must match** — Single-AZ RIs don't apply to Multi-AZ instances or vice versa |
| License model | exact (e.g., LI vs BYOL for Oracle/SQL Server) |
| Aurora I/O-Optimized | separate RI category from standard Aurora |

### Discount

Roughly:

| Term + Payment | Discount |
|---|---|
| 1yr No Upfront | ~30% |
| 1yr All Upfront | ~40% |
| 3yr No Upfront | ~50% |
| 3yr All Upfront | ~60% |

### Practical Notes

- **Multi-AZ traps:** if you have Single-AZ in non-prod and Multi-AZ in prod, buy them as separate RIs. A Single-AZ RI does not apply to a Multi-AZ instance.
- **Aurora:** RIs apply to Aurora cluster instance hours. Aurora Serverless v2 ACU usage is **not** RI-eligible.
- **Right-size first.** RIs lock you in. Don't reserve an oversized instance.
- **Engine swap risk:** if there's any chance of moving from RDS Postgres to Aurora Postgres (or vice versa), don't reserve 3yr — RIs are not interchangeable.

### Recommended Default

For a steady-state prod RDS instance: **1-year All Upfront if cash available, else 1-year No Upfront**, sized to current usage. Re-evaluate annually.

---

## ElastiCache Reserved Nodes

**No Savings Plan exists. No size flexibility.** This is the strictest of all reservations.

### Scoping (must match exactly)

| Attribute | Match required |
|---|---|
| Cache engine | Redis or Memcached (not interchangeable) |
| Node type | **exact** (`cache.m6g.large` ≠ `cache.m6g.xlarge`) |
| Region | regional |

### Discount

Roughly:

| Term + Payment | Discount |
|---|---|
| 1yr No Upfront | ~30% |
| 1yr All Upfront | ~45% |
| 3yr All Upfront | ~60% |
| 3yr Heavy Utilization (legacy) | up to ~63% |

### Practical Notes

- **No size flex** means a `cache.r6g.large` reservation does *not* apply to a `cache.r6g.xlarge`. Get sizing right before reserving.
- **Cluster mode:** reservations apply per node. A 3-node Redis cluster needs 3 reserved nodes.
- **Replicas count:** every replica node uses node-hours and consumes a reservation slot.
- **Graviton:** `cache.m6g` / `cache.r6g` are ~20% cheaper than equivalent `m5`/`r5`. Migrate before reserving.
- **Serverless ElastiCache:** uses ElastiCache Processing Units (ECPUs); **not RI-eligible**.

### Recommended Default

Reserve only the nodes you've validated as steady-state. Often safer to do **1yr No Upfront** the first time around — under-utilized ElastiCache reserved nodes are common because cluster topology changes.

---

## OpenSearch Reserved Instances

**No Savings Plan. No size flexibility.** Similar discipline to ElastiCache.

### Scoping

| Attribute | Match required |
|---|---|
| Instance type | **exact** (`r6g.large.search` ≠ `r6g.xlarge.search`) |
| Region | regional |
| Applies to | **data nodes only** — does **not** cover dedicated master nodes or UltraWarm/cold nodes |

### Discount

Roughly:

| Term + Payment | Discount |
|---|---|
| 1yr No Upfront | ~30% |
| 1yr All Upfront | ~40% |
| 3yr All Upfront | ~50% |

### Practical Notes

- **Data nodes only.** Master nodes are charged separately and not reservable in the same RI; they're usually small and not worth optimizing.
- **UltraWarm / cold nodes:** different pricing model (object storage based); not RI-eligible. They're already cheap; focus reservations on hot data nodes.
- **Serverless OpenSearch:** uses OCUs; **not RI-eligible**.
- **Graviton (`r6g`, `m6g`, `c6g`):** ~20% cheaper than equivalent x86. Migrate before reserving.
- **Sizing changes a lot during early life of a cluster.** Reserve only after at least 60-90 days of stable usage.

---

## Redshift Reserved Nodes

### Scoping

| Attribute | Match required |
|---|---|
| Node type | **exact** (`ra3.4xlarge` ≠ `ra3.16xlarge`) |
| Region | regional |

### Discount

| Term + Payment | Discount |
|---|---|
| 1yr No Upfront | ~20% |
| 1yr All Upfront | ~40% |
| 3yr All Upfront | ~70% |

### Practical Notes

- AWS retired DC2/DS2 reserved purchases; **RA3 only** for new purchases.
- Redshift Serverless uses RPUs; **not RI-eligible**.
- 3-year All Upfront has the largest absolute discount of any reserved purchase in AWS — but only if usage is genuinely stable.

---

## DynamoDB Reserved Capacity

### Scoping

- Provisioned mode only; **on-demand tables are not eligible**.
- Reserves **RCUs and WCUs separately** (you buy them as separate reservations).
- Regional.

### Discount

| Term | Discount |
|---|---|
| 1yr | ~50% |
| 3yr | ~75% |

### Practical Notes

- Minimum purchase: 100 RCU or 100 WCU.
- If your tables are on **on-demand**, switch to **provisioned with Auto Scaling** before reserving.
- Easy to over-buy if traffic is bursty. Aim for the **floor** of your provisioned capacity, not the peak.

---

## Modification and Exchange Rules

| Reservation | Modify | Exchange | Sell on Marketplace |
|---|---|---|---|
| Compute SP / EC2 Instance SP | no | no (auto-flexes within scope) | no |
| Standard RI (EC2) | size + AZ + scope (within family + region) | no | yes (US accounts only) |
| Convertible RI (EC2) | as Standard | yes (for ≥ value) | no |
| RDS RI | yes (size + AZ within family) | no | no |
| ElastiCache reserved node | no | no | no |
| OpenSearch RI | no | no | no |
| Redshift reserved node | no | no | no |
| DynamoDB reserved capacity | no | no | no |

**Implication:** for the strict ones (ElastiCache, OpenSearch, Redshift, DynamoDB), you can't fix mistakes — you can only let the term expire. Be conservative with term length.

---

## Coordinated Purchase Plan — A Worked Example

A typical mid-size SaaS account, $80k/month:
- $35k EC2 + Fargate + Lambda (mixed)
- $20k RDS (Postgres prod Multi-AZ + Postgres staging Single-AZ + a dev instance)
- $6k ElastiCache (Redis cluster for prod)
- $4k OpenSearch (logs cluster)
- $15k everything else (S3, networking, etc.)

Recommended portfolio (1-year No Upfront throughout for simplicity):

1. **Compute Savings Plan**: cover ~70% of steady $35k EC2/Fargate/Lambda baseline = **~$24k/hr-equivalent commit**. ~$78k/year saved.
2. **RDS RI** for prod Postgres Multi-AZ (steady state). **Do not reserve** staging Single-AZ (different scoping; usage may shift). Don't reserve dev. ~$50k/year saved on prod alone.
3. **ElastiCache reserved nodes** matching the exact prod Redis node count + type. Skip if cluster topology has changed in last 90 days. ~$18k/year saved.
4. **OpenSearch RI** only on the data node tier; only after 60+ days of stable instance type. ~$12k/year saved.

Total: ~$158k/year saved on $960k/year spend, with no 3-year lock-in. Re-evaluate every quarter as expirations approach.

---

## Buying Workflow

1. **Wait until you have 30+ days of usage data** for a workload before reserving anything.
2. **Right-size first.** Reservations magnify whatever sizing decision you make.
3. **Use Cost Explorer → Recommendations** as a starting point. It does the math but doesn't know your business plans (architecture changes, migrations, sunsetting).
4. **Buy in tranches**, not all at once. Stagger expirations across quarters so renewal/decision load is spread out.
5. **Set utilization + coverage alerts** in AWS Budgets the day you buy. See `tooling.md`.
6. **Track expirations** at least 60 days out — `scripts/reservation-coverage.sh --expiring-days 60`.
7. **Review quarterly.** Adjust the next tranche based on actual utilization and architectural changes.
