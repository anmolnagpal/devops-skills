# Azure Cost Intelligence Skills
> OpenClaw.ai + Claude | Sellable Skill Pack

---

## Skill 1 — Azure Spend Analyzer

**What it does**: Ingest Azure billing exports or connect via Cost Management API to identify top cost drivers, waste patterns, and anomalies across subscriptions and management groups.

**Input**:
- Azure billing export (CSV) or Subscription ID + read-only credentials
- Optional: resource tag taxonomy (environment, team, project, owner)

**Output**:
- Top 10 cost drivers by service, resource group, and subscription
- Untagged spend % and estimated unallocated cost
- MoM spend delta with anomaly flags
- Natural-language executive summary with action priorities

**Claude's Role**: Interprets Azure billing structure (meters, resource groups, management groups), writes cost narrative, contextualizes anomalies, generates plain-English recommendations.

**Key Azure Services Covered**: Azure VMs, Azure SQL, Blob Storage, AKS, App Service, Azure Functions, ExpressRoute, Bandwidth

**Competitive Edge Over**: Azure Cost Management (no narrative), Cloudability (expensive)

**Monetization**: Pro — $29/mo

---

## Skill 2 — Azure Reservations & Hybrid Benefit Advisor

**What it does**: Analyze Azure VM and SQL usage patterns to recommend optimal Reservation coverage and identify Hybrid Benefit opportunities for maximum stacked savings.

**Input**:
- VM + SQL + managed service usage history (30/90 days via Cost Management API)
- Existing reservation inventory (optional)
- On-premises license inventory for Hybrid Benefit (optional)

**Output**:
- Recommended Azure Reservations by service (VMs, SQL DB, AKS, Cosmos DB, etc.)
- Hybrid Benefit eligibility: Windows Server + SQL Server licenses
- Stacked savings scenario: Reservation + AHB combined
- Break-even timeline per commitment
- Recommended term: 1-year vs 3-year per workload

**Claude's Role**: Explains Hybrid Benefit licensing rules in plain English, calculates stacked discount scenarios, flags workloads NOT suitable for reservations (e.g., dev/test, auto-scaling tiers).

**2025 Notes**:
- Azure Reservations can save up to 72% vs PAYG
- Azure Hybrid Benefit adds 36% (Windows) or 28% (SQL) on top
- Combine both for up to 80%+ savings on stable workloads

**Competitive Edge Over**: Azure Advisor (recommendations without narrative), manual TCO calculators

**Monetization**: Pro — $29/mo

---

## Skill 3 — Azure Idle & Zombie Resource Detector

**What it does**: Identify Azure resources consuming cost with zero meaningful utilization — VMs, disks, IPs, load balancers, and more.

**Input**:
- Azure Resource Graph query export or Subscription access (read-only)
- Azure Monitor metrics (CPU, connections, IOPS)

**Output**:
- Categorized waste list:
  - Stopped (deallocated) VMs still paying for managed disks
  - Unattached managed disks
  - Unused Public IP addresses
  - Idle Application Gateways (0 backend connections)
  - Empty Azure Storage accounts
  - Idle Azure SQL databases (< 1% DTU over 7 days)
  - Unused ExpressRoute circuits
  - Orphaned snapshots older than 90 days
- Estimated monthly cost per item
- Azure CLI/PowerShell cleanup commands per resource

**Claude's Role**: Prioritizes cleanup order by cost impact, flags resources needing human confirmation, generates runbook with Azure CLI commands.

**Monetization**: Pro — $29/mo

---

## Skill 4 — Azure Dev/Test & Auto-Shutdown Optimizer

**What it does**: Identify non-production resources running 24/7 and design auto-shutdown schedules + Dev/Test pricing enrollment strategies.

**Input**:
- Resource tags indicating environment (dev, test, staging)
- Azure Monitor VM uptime metrics

**Output**:
- VMs eligible for auto-shutdown (nights, weekends)
- Estimated savings from scheduling (typically 60–70% of dev VM cost)
- Dev/Test subscription eligibility assessment (up to 55% savings on Windows VMs)
- Azure Automation runbook templates for scheduled start/stop
- Logic App workflow for schedule management

**Claude's Role**: Calculates per-environment savings scenarios, writes Azure Automation runbook descriptions, generates policy recommendations.

**Monetization**: Pro — $29/mo

---

## Skill 5 — Azure Tagging & Cost Allocation Auditor

**What it does**: Audit Azure resource tagging compliance and identify the spend that cannot be allocated to teams, projects, or environments.

**Input**:
- Azure Resource Graph export or subscription access
- Required tag schema

**Output**:
- % of spend with compliant tags vs untagged
- Top untagged resources ranked by monthly cost
- Tagging compliance score per subscription / resource group
- Azure Policy definitions for tag enforcement
- Inheritance gap analysis (resource group tags not propagating)

**Claude's Role**: Explains cost allocation impact, generates Azure Policy JSON for enforcement, writes remediation priority plan.

**Monetization**: Pro — $29/mo

---

## Skill 6 — Azure FinOps Monthly Report Generator

**What it does**: Generate executive-ready monthly FinOps reports across Azure subscriptions and management groups, with team-level chargeback/showback data.

**Input**:
- Azure Cost Management billing export
- Subscription-to-team/department mapping
- Budget configurations (optional)

**Output**:
- Executive summary: total spend, MoM trend, budget utilization
- Per-team / per-subscription breakdown
- Azure service cost heatmap
- Top 5 optimization opportunities with savings estimates
- Chargeback allocation table
- Markdown or PDF-ready format

**Claude's Role**: Writes full narrative, contextualizes overruns vs budget, drafts action items per team, adapts tone for finance vs engineering audience.

**2025 Notes**: Aligned with FinOps Foundation FOCUS 1.2 data model for unified multi-cloud billing.

**Monetization**: Business — $79/mo

---

## Skill 7 — Azure Cost Anomaly Explainer

**What it does**: When Azure Cost Management anomaly detection fires, instantly diagnose the root cause and generate a plain-English incident summary.

**Input**:
- Azure Cost anomaly alert payload (via webhook or email trigger)
- Optional: Azure Activity Log from the anomaly window

**Output**:
- Root cause analysis (e.g. "AKS node pool auto-scaled aggressively due to memory pressure")
- Affected subscription, resource group, and service
- Estimated total impact ($)
- Immediate containment action
- Azure Policy or budget alert recommendation to prevent recurrence

**Claude's Role**: Correlates billing spike with Activity Log and service events, writes incident RCA, generates follow-up ticket content.

**Monetization**: Pro — $29/mo

---

## Skill 8 — Azure Bandwidth & Egress Cost Optimizer

**What it does**: Identify and reduce Azure bandwidth charges — often invisible until they become a major line item.

**Input**:
- Azure Network Watcher flow logs or Cost Management bandwidth breakdown
- Architecture overview (regions, services, CDN usage)

**Output**:
- Bandwidth cost breakdown: inter-region, internet egress, Private Link vs public
- Regions with highest egress charges
- Azure CDN / Front Door offload opportunity assessment
- Private Endpoint migration candidates (reduce egress via public internet)
- Estimated savings per recommendation

**Claude's Role**: Explains each traffic cost driver, calculates ROI of CDN vs direct egress, generates architecture change proposal.

**Monetization**: Business — $79/mo

---

## 💡 Azure Cost Pack — Cross-Skill Features

| Feature | Description |
|---|---|
| **Ask Claude** | Natural-language follow-up on any finding |
| **Teams Digest** | Weekly cost summary to Microsoft Teams |
| **Azure DevOps Work Item** | Auto-generate work items from recommendations |
| **Power BI Export** | Cost data formatted for Power BI dashboards |
| **Bicep/ARM Snippet** | Generate IaC for recommended changes |

---

## 📦 Azure Cost Pack Pricing

| Tier | Price | Includes |
|---|---|---|
| Free | $0 | Skill 3 (Idle Detector), 5 scans/mo |
| Pro | $29/mo | Skills 1–5, 7 |
| Business | $79/mo | All 8 skills + Reports + API |
| Enterprise | Custom | White-label + dedicated Claude model |

---

## 🛠️ Tech Stack

- **LLM**: Claude (claude-3-5-sonnet for analysis, claude-3-opus for reports)
- **Data Sources**: Azure Cost Management API, Resource Graph, Azure Monitor, Activity Log
- **Output**: Markdown, JSON, PDF
- **Integrations**: Microsoft Teams, Azure DevOps, Jira, Power BI
