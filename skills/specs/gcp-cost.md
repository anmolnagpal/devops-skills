# GCP Cost Intelligence Skills
> OpenClaw.ai + Claude | Sellable Skill Pack

---

## Skill 1 — GCP Spend Analyzer

**What it does**: Ingest GCP Billing exports (BigQuery or CSV) to surface top cost drivers, service-level waste, and spend anomalies across projects and folders.

**Input**:
- GCP Billing export from BigQuery or CSV
- Optional: label taxonomy (team, environment, project, owner)

**Output**:
- Top 10 cost drivers by service, project, and SKU
- Unlabeled spend % and unallocatable cost estimate
- MoM delta with anomaly flags
- Natural-language executive summary with action priorities

**Claude's Role**: Interprets GCP billing SKU structure (which is notoriously complex), writes cost narrative, contextualizes anomalies, generates ranked action list.

**Key GCP Services Covered**: Compute Engine, GKE, Cloud SQL, Cloud Storage, BigQuery, Cloud Run, Pub/Sub, Networking/Egress

**GCP Nuance**: GCP billing is SKU-based (1000s of SKUs) — Claude translates SKU codes into human-readable service names and explains cost drivers in plain English.

**Competitive Edge Over**: GCP Billing Reports (no narrative, raw SKUs), Looker Studio dashboards (no AI insights)

**Monetization**: Pro — $29/mo

---

## Skill 2 — Committed Use Discount (CUD) Advisor

**What it does**: Analyze Compute Engine and GKE usage to recommend optimal CUD portfolio — spend-based vs resource-based — with break-even and risk analysis.

**Input**:
- GCP Compute Engine + Cloud Run + GKE usage history (30/90 days)
- Existing CUD commitments (optional)

**Output**:
- Recommended CUD type per workload:
  - Spend-based CUDs (flexible, cross-service) — up to 28% savings
  - Resource-based CUDs (vCPU/RAM committed) — up to 57% savings
- Coverage gap % by region and machine family
- Sustained Use Discount (SUD) interaction analysis
- Recommended 1-year vs 3-year split
- Under-commitment risk: conservative vs aggressive scenarios

**Claude's Role**: Explains spend-based vs resource-based CUD trade-offs, flags workloads that already benefit from SUDs (automatic), identifies Preemptible/Spot VM candidates for further savings.

**2025 Notes**:
- GCP now supports CUDs for Cloud Run and GKE Autopilot (2025 expansion)
- Spend-based CUDs now cover most managed services — broader than before

**Competitive Edge Over**: ProsperOps (expensive), GCP Recommender (no explanations, no scenarios)

**Monetization**: Pro — $29/mo

---

## Skill 3 — GCP Idle & Zombie Resource Detector

**What it does**: Identify GCP resources with zero or near-zero utilization that are silently accumulating cost.

**Input**:
- GCP Cloud Asset Inventory export or project access (read-only via Service Account)
- Cloud Monitoring metrics

**Output**:
- Categorized waste list:
  - Idle Compute Engine instances (< 1% CPU over 7 days)
  - Unattached Persistent Disks
  - Unused Static External IP addresses
  - Idle Cloud SQL instances
  - Empty GCS buckets incurring class A/B operation fees
  - Idle GKE node pools (unutilized nodes)
  - Unused Cloud NAT gateways
  - Orphaned snapshots older than 90 days
- Estimated monthly cost per item
- `gcloud` CLI commands for each cleanup action

**Claude's Role**: Prioritizes cleanup by cost impact, flags production-risk resources needing human sign-off, generates step-by-step runbook with `gcloud` commands.

**Monetization**: Pro — $29/mo

---

## Skill 4 — GCP Preemptible / Spot VM Strategy Builder

**What it does**: Identify workloads eligible for Preemptible or Spot VMs and design an interruption-resilient strategy with managed instance group fallbacks.

**Input**:
- Compute Engine fleet details and workload types (batch, ML training, CI/CD, data pipelines)
- Current on-demand spend on target instances

**Output**:
- Spot/Preemptible-eligible workload list with 60–91% savings estimates
- Interruption risk score per machine type and region
- Managed Instance Group (MIG) configuration for auto-restart
- Fallback strategy: Spot → On-Demand with budget cap
- Dataflow and Dataproc Spot integration recommendations

**Claude's Role**: Explains interruption handling for each workload type, writes MIG configuration rationale, recommends fault-tolerance architecture patterns.

**Monetization**: Pro — $29/mo

---

## Skill 5 — GCP BigQuery Cost Optimizer

**What it does**: BigQuery is the #1 surprise cost driver on GCP — this skill analyzes query patterns, storage usage, and slot consumption to dramatically reduce BigQuery spend.

**Input**:
- BigQuery INFORMATION_SCHEMA.JOBS_BY_PROJECT data
- Dataset and table inventory
- Slot reservation configuration (optional)

**Output**:
- Top 10 most expensive queries ranked by bytes billed
- Users/service accounts running the most expensive queries
- Partition pruning opportunities (queries scanning full tables)
- Long-term vs active storage classification (auto-transition to cheaper storage)
- Slot reservation vs on-demand recommendation
- Materialized view opportunities to cache repeated expensive queries

**Claude's Role**: Explains why each query is expensive, rewrites expensive query patterns in plain English, generates query optimization recommendations and SQL snippets.

**GCP Unique Skill**: No equivalent in AWS or Azure at this depth — BigQuery's pricing model is unique.

**Monetization**: Business — $79/mo

---

## Skill 6 — GCP Networking & Egress Cost Optimizer

**What it does**: GCP egress charges (especially inter-region and internet) are among the most misunderstood costs. This skill diagnoses and reduces them.

**Input**:
- VPC Flow Logs or GCP Billing egress line items
- Architecture overview (regions, services, CDN usage)

**Output**:
- Egress cost breakdown: inter-region, internet, Cloud Interconnect vs public
- Top traffic patterns by source project and destination
- Private Google Access enablement opportunities
- Cloud CDN offload assessment (GCS + Load Balancer)
- Cloud Interconnect vs VPN cost comparison for on-prem traffic
- Estimated savings per recommendation

**Claude's Role**: Translates VPC flow data into architectural cost drivers, calculates CDN vs direct egress ROI, generates network architecture change proposal.

**Monetization**: Business — $79/mo

---

## Skill 7 — GCP FinOps Monthly Report Generator

**What it does**: Generate executive-ready monthly FinOps reports across GCP projects, folders, and billing accounts with team-level allocation.

**Input**:
- GCP Billing export (BigQuery dataset)
- Project-to-team/department mapping
- Budget configurations (optional)

**Output**:
- Executive summary: total spend, MoM trend, top service movers
- Per-team / per-project / per-folder breakdown
- Label coverage score and unallocated spend
- Budget vs actual variance
- Top 5 savings opportunities
- GCP service cost heatmap
- Markdown or PDF-ready format

**Claude's Role**: Writes full narrative, contextualizes budget variances, adapts language for finance vs engineering, drafts team-level action items.

**2025 Notes**: Aligned with FinOps FOCUS 1.2 standard. Supports GCP's new unified billing account structure.

**Monetization**: Business — $79/mo

---

## Skill 8 — GCP Cost Anomaly Explainer

**What it does**: When GCP Budget Alerts fire, instantly diagnose root cause using billing data and Cloud Audit Logs.

**Input**:
- GCP Budget Alert payload (via Pub/Sub webhook)
- Optional: Cloud Audit Logs from the anomaly window

**Output**:
- Root cause analysis (e.g. "BigQuery job run without partition filter scanned 10TB")
- Affected project, service, and principal (user/SA)
- Estimated total impact ($)
- Immediate containment action
- Recommended Budget Alert and IAM constraint to prevent recurrence

**Claude's Role**: Correlates billing spike with Audit Log events, writes incident RCA, generates follow-up ticket content.

**Monetization**: Pro — $29/mo

---

## 💡 GCP Cost Pack — Cross-Skill Features

| Feature | Description |
|---|---|
| **Ask Claude** | Natural-language follow-up on any finding |
| **Slack/Chat Digest** | Weekly cost summary via Slack or Google Chat |
| **Jira/Linear Ticket** | Auto-generate tickets from recommendations |
| **BigQuery Dashboard Export** | Send findings to your own BigQuery dataset |
| **Terraform Snippet** | Generate IaC for recommended changes |

---

## 📦 GCP Cost Pack Pricing

| Tier | Price | Includes |
|---|---|---|
| Free | $0 | Skill 3 (Idle Detector), 5 scans/mo |
| Pro | $29/mo | Skills 1–4, 8 |
| Business | $79/mo | All 8 skills + Reports + API |
| Enterprise | Custom | White-label + dedicated Claude model |

---

## 🛠️ Tech Stack

- **LLM**: Claude (claude-3-5-sonnet for analysis, claude-3-opus for reports)
- **Data Sources**: GCP Billing Export (BigQuery), Cloud Asset Inventory, Cloud Monitoring, VPC Flow Logs, INFORMATION_SCHEMA
- **Output**: Markdown, JSON, PDF
- **Integrations**: Slack, Google Chat, Jira, Looker Studio, BigQuery
