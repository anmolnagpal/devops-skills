# Kubernetes Cost Intelligence Skills
> OpenClaw.ai + Claude | Sellable Skill Pack | Works with EKS · AKS · GKE

---

## Skill 1 — Kubernetes Cluster Cost Analyzer

**What it does**: Break down total Kubernetes spend by namespace, workload, team, and label — making invisible K8s costs visible and allocatable.

**Input**:
- Kubecost export or cloud billing data (EKS/AKS/GKE node costs)
- Kubernetes namespace + label inventory
- Optional: team-to-namespace mapping

**Output**:
- Total cluster cost breakdown:
  - Per namespace (team/project attribution)
  - Per workload (Deployment, StatefulSet, DaemonSet)
  - Per label (env, app, owner)
- CPU vs memory cost split per workload
- Idle/unallocated cost % (cluster overhead waste)
- Top 10 most expensive namespaces/workloads
- Chargeback/showback table per team

**Claude's Role**: Translates raw cost allocation data into team-level narratives, flags the biggest waste contributors, generates executive FinOps summary.

**Cloud-Specific Notes**:
- **EKS**: EC2 node cost + EKS control plane ($0.10/hr per cluster)
- **AKS**: VM node cost (AKS control plane free); ARM-based VMs 30–50% cheaper
- **GKE**: GKE Autopilot per-pod billing vs Standard per-node; control plane fee waived for Autopilot

**Competitive Edge Over**: Kubecost (no narrative/AI), native cloud billing (no K8s-level granularity)

**Monetization**: Pro — $29/mo

---

## Skill 2 — Resource Request & Limit Right-Sizer

**What it does**: Identify over-provisioned and under-provisioned pods by comparing resource requests/limits against actual usage — the #1 source of K8s cost waste.

**Input**:
- Kubernetes metrics (Metrics Server or Prometheus data)
- Pod resource requests and limits (from `kubectl get pods -o json`)
- Historical CPU/memory utilization (last 7–30 days)

**Output**:
- Pods with requests 2x+ above actual P95 usage (over-provisioned)
- Pods with no limits set (risk of resource starvation)
- Pods with requests = limits (no burst headroom — often wrong)
- Cluster bin-packing efficiency score (0–100%)
- Recommended new requests/limits per workload
- Estimated monthly savings from right-sizing
- VPA (Vertical Pod Autoscaler) configuration recommendations

**Claude's Role**: Explains why each misconfiguration is wasteful or risky, generates corrected YAML manifests with recommended resource values, writes Helm values patch.

**2025 Notes**: Over-provisioning CPU requests is the most common K8s waste pattern — teams typically reclaim 30–50% cluster cost after right-sizing.

**Monetization**: Pro — $29/mo

---

## Skill 3 — Node Pool & Autoscaling Optimizer

**What it does**: Analyze node pool composition and autoscaling configuration to eliminate idle node waste and optimize instance type selection.

**Input**:
- Node pool configuration (instance types, min/max, current size)
- Node utilization metrics (CPU/memory per node over 7 days)
- Cluster Autoscaler or Karpenter logs (optional)

**Output**:
- Nodes consistently running at < 20% utilization (oversized or excess)
- Node pools with poor bin-packing (too many instance types, fragmentation)
- Autoscaler configuration gaps:
  - Scale-down delay too long (idle nodes not removed fast enough)
  - Min node count too high for off-hours
  - Missing expander strategy
- Recommended instance type mix per workload profile
- Karpenter provisioner configuration (for EKS) recommendations
- GKE Node Auto-Provisioning tuning recommendations

**Claude's Role**: Explains the bin-packing economics of each node pool config, generates Karpenter provisioner YAML or Cluster Autoscaler config, writes scaling strategy rationale.

**Monetization**: Pro — $29/mo

---

## Skill 4 — Spot / Preemptible Node Strategy Builder

**What it does**: Design an interruption-resilient spot/preemptible node strategy for K8s workloads — the fastest path to 60–90% node cost reduction.

**Input**:
- Workload inventory (Deployments, Jobs, DaemonSets) with replica counts
- Current node pool pricing (on-demand vs spot)
- Existing Pod Disruption Budgets (PDBs)

**Output**:
- Workload eligibility matrix: spot-safe vs spot-unsafe
- Multi-AZ spot diversification strategy (instance family + zone spread)
- PDB recommendations per workload (tolerate 1 interruption at a time)
- Node taints + tolerations YAML for spot node isolation
- Fallback on-demand node pool configuration
- Per-workload estimated savings

**Cloud-Specific**:
- **EKS**: Karpenter spot interruption handling + EC2 Spot placement score
- **AKS**: Spot node pool with eviction policy + Azure Spot priority
- **GKE**: Spot VMs (replacing Preemptible) + Graceful eviction configuration

**Claude's Role**: Classifies each workload's interruption tolerance, generates complete spot node pool configuration YAML per cloud, writes PDB and toleration patches.

**Monetization**: Pro — $29/mo

---

## Skill 5 — Idle & Zombie Workload Detector

**What it does**: Find K8s workloads, namespaces, and persistent volumes consuming resources with zero meaningful activity.

**Input**:
- Kubernetes workload inventory (`kubectl get all -A`)
- Pod metrics (CPU/memory usage, last 7 days)
- PersistentVolume inventory

**Output**:
- Zombie workloads:
  - Deployments with 0 traffic and 0 CPU usage for 7+ days
  - CronJobs that haven't run successfully in 30+ days
  - Jobs stuck in Pending state
  - Completed pods not cleaned up (consuming namespace quota)
- Orphaned resources:
  - Unbound PersistentVolumeClaims
  - PersistentVolumes in Released state
  - Unused ConfigMaps and Secrets
  - Stale Ingress rules pointing to deleted services
- Estimated monthly cost per zombie resource
- `kubectl delete` commands for safe cleanup

**Claude's Role**: Triages each finding for deletion safety, flags stateful workloads needing manual review, generates cleanup runbook with rollback notes.

**Monetization**: Pro — $29/mo

---

## Skill 6 — Namespace Cost Chargeback Report Generator

**What it does**: Generate monthly chargeback/showback reports at namespace or team level — enabling engineering teams to own their K8s spend.

**Input**:
- Cluster cost data (from cloud billing or Kubecost)
- Namespace-to-team mapping
- Shared infrastructure allocation rules (control plane, DaemonSets, system namespaces)

**Output**:
- Per-team monthly cost statement
- Shared cost allocation methodology (proportional, equal split, or custom)
- Budget vs actual variance per team
- Top wasteful workloads per team
- MoM cost trend per namespace
- Engineering-friendly and finance-friendly report variants

**Claude's Role**: Writes narrative per team (e.g. "Team Payments increased spend 34% due to a new StatefulSet deployed Nov 3"), generates fair shared-cost allocation explanation, formats for Slack/Confluence/PDF.

**Monetization**: Business — $79/mo

---

## Skill 7 — Multi-Cluster Cost Comparator (EKS vs AKS vs GKE)

**What it does**: For teams running the same workloads across multiple clouds or evaluating a migration — compare true total cost of ownership per cluster.

**Input**:
- Cluster configurations per cloud (node types, regions, add-ons, support tiers)
- Workload resource profile (CPU/memory totals, storage, egress)

**Output**:
- True TCO breakdown per cluster:
  - Compute (nodes + control plane fees)
  - Storage (persistent volumes)
  - Networking (load balancers, egress, cross-AZ traffic)
  - Add-ons (monitoring, logging, service mesh)
- Side-by-side cost comparison table
- Cost-at-scale projection (2x, 5x, 10x growth)
- Recommended cloud + configuration for cost-optimized K8s

**Claude's Role**: Accounts for hidden K8s costs (AZ egress, NAT, LB fees), explains trade-offs beyond pure compute price, writes migration cost-benefit analysis.

**Monetization**: Business — $79/mo

---

## Skill 8 — K8s FinOps Monthly Report Generator

**What it does**: Auto-generate executive-ready monthly Kubernetes cost reports across all clusters and teams.

**Input**:
- Multi-cluster cost data (Kubecost, cloud billing, or Prometheus)
- Team/namespace mapping across clusters
- Previous month data for comparison

**Output**:
- Total K8s spend across all clusters MoM
- Per-cluster cost efficiency score
- Team-level allocation with budget variance
- Top 5 optimization opportunities with savings estimates
- Cluster utilization trend (idle CPU/memory %)
- Markdown or PDF-ready executive report

**Claude's Role**: Writes full narrative, contextualizes cluster efficiency scores, drafts per-team action items, generates board/CISO-ready summary.

**Monetization**: Business — $79/mo

---

## 💡 Kubernetes Cost Pack — Cross-Skill Features

| Feature | Description |
|---|---|
| **Ask Claude** | Natural-language follow-up on any finding |
| **Slack/Teams Digest** | Weekly cost summary per team |
| **Jira/Linear Ticket** | Auto-generate right-sizing tickets per workload |
| **YAML Patch Generator** | Ready-to-apply resource request patches |
| **Helm Values Generator** | Cost-optimized Helm values per chart |
| **Grafana Dashboard Export** | Cost findings formatted for Grafana |

---

## 📦 Kubernetes Cost Pack Pricing

| Tier | Price | Includes |
|---|---|---|
| Free | $0 | Skill 5 (Idle Detector), 3 scans/mo |
| Pro | $29/mo | Skills 1–5 |
| Business | $79/mo | All 8 skills + Reports + API |
| Enterprise | Custom | White-label + dedicated Claude + multi-cluster |

---

## 🛠️ Tech Stack

- **LLM**: Claude (claude-3-5-sonnet for analysis, claude-3-opus for reports)
- **Data Sources**: Kubernetes API, Metrics Server, Prometheus, Kubecost, Cloud Billing APIs
- **Clouds**: EKS (AWS) · AKS (Azure) · GKE (GCP)
- **Output**: Markdown, JSON, YAML patches, PDF
- **Integrations**: Slack, Teams, Jira, Grafana, Helm, ArgoCD
