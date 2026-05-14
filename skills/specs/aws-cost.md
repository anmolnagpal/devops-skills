# AWS Cost Intelligence Skills
> OpenClaw.ai + Claude | Sellable Skill Pack

---

## Skill 1 — AWS Spend Analyzer

**What it does**: Ingest AWS Cost & Usage Reports (CUR) or Cost Explorer exports. Identify top cost drivers, MoM anomalies, and per-service waste across all linked accounts.

**Input**:
- CUR CSV/JSON export or AWS account ID + credentials (read-only)
- Optional: tag taxonomy (team, env, project)

**Output**:
- Top 10 cost drivers ranked by spend
- % waste per service (idle, untagged, over-provisioned)
- MoM delta with anomaly flags
- Natural-language executive summary

**Claude's Role**: Interprets raw billing data, writes cost narrative, flags anomalies in plain English, generates action-ranked savings list.

**Key AWS Services Covered**: EC2, RDS, S3, Lambda, EKS, ECS, CloudFront, NAT Gateway, Data Transfer

**Competitive Edge Over**: AWS Cost Explorer (no narrative), Trusted Advisor (no CUR depth)

**Monetization**: Pro — $29/mo

---

## Skill 2 — Reserved Instance & Savings Plans Advisor

**What it does**: Analyze on-demand usage patterns over 30/60/90 days and recommend optimal RI/Savings Plan portfolio with break-even timelines and risk scoring.

**Input**:
- EC2, RDS, ElastiCache, Redshift, Lambda usage history
- Current RI/SP coverage (optional)

**Output**:
- Recommended commitment type: Compute SP / EC2 SP / RI (Standard vs Convertible)
- Coverage gap % per service
- Estimated annual savings (conservative / aggressive scenario)
- Break-even analysis per recommendation
- Risk level: Low / Medium / High (based on workload variability)

**Claude's Role**: Explains SP vs RI trade-offs for each workload, generates finance-ready summary, flags workloads unsuitable for commitment (e.g. bursty ML jobs).

**2025 Notes**:
- Database Savings Plans now cover managed databases (launched 2025) — skill covers this
- 1-year no-upfront SP recommended for growing workloads; 3-year all-upfront for stable prod

**Competitive Edge Over**: ProsperOps (expensive, black-box), AWS native recommendations (no explanation)

**Monetization**: Pro — $29/mo

---

## Skill 3 — Idle & Zombie Resource Detector

**What it does**: Scan AWS account for resources consuming cost with zero or near-zero utilization.

**Input**:
- AWS account access (read-only via IAM role) or exported inventory JSON

**Output**:
- Categorized waste list:
  - Stopped EC2 instances still paying for EBS
  - Unattached EBS volumes
  - Unused Elastic IPs
  - Idle load balancers (0 active connections)
  - Empty/near-empty S3 buckets
  - Unused NAT Gateways
  - Orphaned snapshots older than 90 days
  - Idle RDS instances (< 1% CPU over 7 days)
- Estimated monthly cost per item
- Cleanup priority order

**Claude's Role**: Triage severity, generate cleanup runbook, flag resources that need human confirmation before deletion.

**Competitive Edge Over**: Trusted Advisor (limited free tier), CloudHealth (expensive)

**Monetization**: Pro — $29/mo

---

## Skill 4 — Spot Instance Strategy Builder

**What it does**: Identify workloads eligible for Spot and design an interruption-resilient Spot strategy with fallback options.

**Input**:
- EC2 fleet configuration and workload type (batch, CI/CD, ML training, web tier)
- Current On-Demand spend on target instances

**Output**:
- Spot-eligible workload list with estimated savings (70–90% vs On-Demand)
- Recommended instance diversification (family + AZ spread)
- Interruption risk score per instance type (using Spot placement score data)
- Fallback architecture: Spot → On-Demand → Savings Plan layering
- Auto Scaling Group configuration recommendations

**Claude's Role**: Explains interruption risk for each instance type, writes Spot fleet config rationale, generates architecture decision record (ADR).

**Monetization**: Pro — $29/mo

---

## Skill 5 — AWS Tagging & Cost Allocation Auditor

**What it does**: Detect untagged or inconsistently tagged resources that make cost allocation impossible for FinOps teams.

**Input**:
- AWS Config snapshot or tag inventory export
- Required tag schema (e.g. `env`, `team`, `project`, `owner`)

**Output**:
- % of spend covered by tags vs untagged
- Resources missing required tags, ranked by cost impact
- Tagging consistency score (0–100)
- Auto-generated tagging policy enforcement rules (AWS Config rules + SCPs)

**Claude's Role**: Explains cost allocation impact of each untagged resource, generates tag remediation plan, writes AWS Config rule JSON.

**Monetization**: Pro — $29/mo

---

## Skill 6 — Multi-Account FinOps Report Generator

**What it does**: Generate executive-ready monthly FinOps reports across AWS Organizations accounts with team-level chargeback/showback.

**Input**:
- AWS Organizations billing data (CUR or Cost Explorer API)
- Account-to-team mapping
- Previous month comparison data

**Output**:
- Executive summary: total spend, MoM trend, biggest movers
- Per-team / per-account breakdown
- Budget vs actual variance
- Top 5 optimization opportunities with estimated savings
- Markdown or PDF-ready format

**Claude's Role**: Writes the entire narrative, contextualizes budget overruns, drafts recommended actions per team, formats for finance and engineering audiences.

**2025 Notes**: Aligned with FinOps FOCUS 1.2 data model standard for unified billing.

**Competitive Edge Over**: CloudZero (expensive), manual spreadsheets

**Monetization**: Business — $79/mo

---

## Skill 7 — AWS Cost Anomaly Explainer

**What it does**: When AWS Cost Anomaly Detection fires an alert, diagnose root cause and explain the spike in plain English within seconds.

**Input**:
- Cost anomaly alert payload (from AWS Cost Anomaly Detection webhook or SNS)
- Optional: CloudTrail events from the anomaly window

**Output**:
- Probable root cause (e.g. "Lambda invocation spike due to misconfigured event trigger")
- Affected service and account
- Estimated total impact ($)
- Immediate containment action
- Recurrence prevention recommendation

**Claude's Role**: Correlates billing spike with service events, writes incident-style root cause analysis, generates Jira/Linear ticket body.

**Monetization**: Pro — $29/mo

---

## Skill 8 — AWS Data Transfer Cost Optimizer

**What it does**: Identify and reduce expensive inter-region, cross-AZ, and NAT Gateway data transfer costs — often the most overlooked AWS cost driver.

**Input**:
- VPC Flow Logs or Cost Explorer data transfer breakdown
- Architecture diagram (optional)

**Output**:
- Data transfer cost breakdown by type: inter-AZ, inter-region, internet egress, NAT
- Top traffic patterns driving cost
- Architecture recommendations: VPC Endpoints, same-AZ placement, CloudFront offload
- Estimated savings per recommendation

**Claude's Role**: Explains each traffic pattern, calculates savings math, generates architecture change proposal.

**Monetization**: Business — $79/mo

---

## 💡 AWS Cost Pack — Cross-Skill Features

| Feature | Description |
|---|---|
| **Ask Claude** | Natural-language follow-up on any finding |
| **Slack Digest** | Weekly cost summary to Slack |
| **Jira/Linear Ticket** | Auto-generate tickets from recommendations |
| **Savings Tracker** | Track realized savings over time |
| **Terraform Snippet** | Generate IaC for recommended changes |

---

## 📦 AWS Cost Pack Pricing

| Tier | Price | Includes |
|---|---|---|
| Free | $0 | Skill 3 (Idle Detector), 5 scans/mo |
| Pro | $29/mo | Skills 1–5, 7 |
| Business | $79/mo | All 8 skills + Reports + API |
| Enterprise | Custom | White-label + dedicated Claude model |

---

## 🛠️ Tech Stack

- **LLM**: Claude (claude-3-5-sonnet for analysis, claude-3-opus for reports)
- **Data Sources**: AWS CUR, Cost Explorer API, Config API, CloudTrail, VPC Flow Logs
- **Output**: Markdown, JSON, PDF
- **Integrations**: Slack, Jira, PagerDuty, Datadog
