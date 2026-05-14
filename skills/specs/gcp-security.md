# GCP Security Skills
> OpenClaw.ai + Claude | Sellable Skill Pack

---

## Skill 1 — GCP IAM Policy Auditor

**What it does**: Deep-audit GCP IAM policies, bindings, service accounts, and custom roles for over-privilege, dangerous patterns, and least-privilege violations.

**Input**:
- GCP IAM policy export (via `gcloud projects get-iam-policy` or Cloud Asset Inventory)
- Service account key inventory (optional)

**Output**:
- Risk-scored findings:
  - Primitive roles (Owner, Editor, Viewer) assigned at project/folder/org level
  - AllUsers or allAuthenticatedUsers bindings (public access)
  - Service accounts with excessive roles
  - Service account keys (long-lived credentials) in use
  - Cross-project impersonation risks (`iam.serviceAccounts.actAs`)
  - Org-level bindings that cascade to all projects
  - Unused bindings (accounts with no recent activity per Policy Analyzer)
- Safer binding recommendations (predefined vs custom roles)
- MITRE ATT&CK Cloud mapping for high-risk permissions (Privilege Escalation, Lateral Movement)

**Claude's Role**: Explains each risky binding in plain English, maps to real GCP attack scenarios (e.g. "Editor on project X allows full compute takeover"), generates corrected IAM policy JSON with inline comments.

**2025 Threat Context**: GCP's primitive roles (Editor/Owner) are still found in ~60% of assessed environments. Service account key leakage is the #1 GCP initial access vector.

**Monetization**: Security — $49/mo

---

## Skill 2 — GCP VPC Firewall Rule Auditor

**What it does**: Audit GCP VPC firewall rules and hierarchical firewall policies for dangerous internet exposure and lateral movement risks.

**Input**:
- VPC firewall rules export (JSON) or project access (read-only)
- Hierarchical firewall policies (org/folder level, optional)
- Network topology overview

**Output**:
- Critical findings:
  - `0.0.0.0/0` source on SSH (22), RDP (3389), database ports (3306, 5432, 27017)
  - Wide-open ingress rules on default VPC network (a GCP default risk)
  - Rules using broad IP ranges without source tags
  - Firewall rules with no logging enabled (blind spots for incident response)
  - Overly permissive allow-all rules between subnets
  - Default network still in use (GCP legacy, inherits permissive rules)
- Blast radius estimate per rule
- Corrected firewall rule `gcloud` commands
- VPC Service Controls recommendations for sensitive APIs

**Claude's Role**: Explains attack surface for each risky rule, generates corrected firewall rules as `gcloud` commands, recommends network segmentation architecture.

**Monetization**: Security — $49/mo

---

## Skill 3 — GCP Cloud Storage Exposure Auditor

**What it does**: Identify publicly accessible GCS buckets, dangerous ACLs, and misconfigured uniform bucket-level access settings.

**Input**:
- GCS bucket list + IAM policies + ACL export (via `gsutil` or Cloud Asset Inventory)
- Organization-level Public Access Prevention setting

**Output**:
- Buckets with `allUsers` or `allAuthenticatedUsers` bindings (fully public)
- Buckets with Object ACLs still active (uniform bucket-level access not enforced)
- Buckets without Public Access Prevention at org or bucket level
- Buckets lacking CMEK (customer-managed encryption key)
- Buckets without object versioning (ransomware risk)
- Buckets without audit logging (Data Access logs not enabled)
- Signed URLs with excessive permissions or far-future expiry

**Claude's Role**: Assesses data exposure risk per bucket (naming/label heuristic for PII/sensitive data), generates hardened bucket IAM policy JSON, writes remediation runbook with `gsutil` and `gcloud` commands.

**Monetization**: Security — $49/mo

---

## Skill 4 — GCP Security Command Center (SCC) Triage Assistant

**What it does**: Process Security Command Center findings and generate a prioritized, plain-English remediation plan — cutting through alert fatigue.

**Input**:
- SCC findings export (JSON via API or CSV) or SCC API access
- Finding categories: THREAT, VULNERABILITY, MISCONFIGURATION, OBSERVATION

**Output**:
- Findings ranked by real-world risk (not just SCC severity score)
- Top 10 critical findings with immediate action required
- False positive likelihood assessment per finding
- Categorized remediation roadmap:
  - Fix today (active threat indicators)
  - Fix this week (high-severity misconfigs)
  - Fix this quarter (compliance gaps)
- Attack path analysis: which findings chain together for lateral movement
- Automated remediation options per finding (where available)

**Claude's Role**: Translates SCC finding IDs and technical descriptions into business-impact narratives, chains related findings into attack paths, generates prioritized remediation plan.

**2025 Notes**: Covers new SCC Enterprise features: toxic combination detection, cloud security graph, DSPM findings, and Mandiant threat intelligence integration.

**Monetization**: Security — $49/mo

---

## Skill 5 — GCP Service Account & Key Security Auditor

**What it does**: Service account misuse is the #1 lateral movement technique in GCP. This skill audits every service account and its keys for dangerous configurations.

**Input**:
- Service account list and role bindings (via IAM export or Cloud Asset Inventory)
- Service account key inventory

**Output**:
- Service accounts with user-managed keys (vs recommended Workload Identity)
- Keys not rotated in > 90 days
- Default service accounts still active (Compute Engine, App Engine defaults)
- Service accounts with Owner or Editor primitive roles
- Service accounts used by humans (should be for workloads only)
- Cross-project service account impersonation chains
- Workload Identity Federation adoption gaps

**Claude's Role**: Explains why each finding is dangerous (e.g. "A leaked key for this SA gives full Editor access to project X"), generates Workload Identity migration guide per workload type, writes key rotation runbook.

**GCP-Unique**: Service account security is far more nuanced in GCP than AWS IAM roles — this skill covers GCP-specific patterns like default SA abuse and key federation.

**Monetization**: Security — $49/mo

---

## Skill 6 — GCP Terraform / IaC Security Reviewer

**What it does**: Review Terraform plans or HCL modules targeting GCP (`google` provider) for security misconfigurations before `terraform apply`.

**Input**:
- `terraform plan` JSON output or `.tf` files with `google` provider resources
- Optional: existing SCC findings for context

**Output**:
- Security findings ranked by severity:
  - GCS buckets with `public_access_prevention = "inherited"` (dangerous default)
  - Cloud SQL with `ipv4_enabled = true` and no authorized networks
  - GKE cluster with legacy authorization enabled
  - GKE cluster without Workload Identity
  - Compute instances with `can_ip_forward = true` unnecessarily
  - Firewall rules with `0.0.0.0/0` source ranges
  - Cloud Functions / Cloud Run with unauthenticated invocation
  - BigQuery datasets with `access[].specialGroup = "allAuthenticatedUsers"`
- Line-level corrected HCL snippets
- CIS GCP Benchmark control mapping per finding

**Claude's Role**: Explains the real-world GCP attack scenario for each misconfiguration, generates corrected Terraform code, writes PR review comment in GitHub-ready format.

**Monetization**: Security — $49/mo

---

## Skill 7 — GCP Cloud Audit Log Threat Detector

**What it does**: Analyze GCP Cloud Audit Logs (Admin Activity, Data Access, System Event) for suspicious patterns and attack indicators.

**Input**:
- Cloud Audit Log export (JSON from BigQuery log sink, last N hours/days)
- Optional: SCC threat findings for correlation

**Output**:
- Flagged high-risk events:
  - Org-level IAM binding changes
  - Service account key creation from unusual principals
  - GCS bucket made public
  - Cloud Audit Logs disabled or log sink deleted
  - Firewall rules opened to internet
  - Mass resource deletion events
  - Unusual cross-project service account impersonation
  - API calls from unexpected geolocations or IPs
  - Cloud Shell sessions from unknown users
- MITRE ATT&CK Cloud technique mapping
- Incident timeline reconstruction
- Immediate containment recommendations

**Claude's Role**: Narrates the attack sequence, chains related events into attack story, generates incident response checklist, writes executive breach summary.

**Monetization**: Security — $49/mo

---

## Skill 8 — GCP Compliance Gap Analyzer

**What it does**: Map your GCP environment against CIS GCP Foundations Benchmark, SOC 2, HIPAA, or PCI-DSS controls and generate a prioritized remediation roadmap.

**Input**:
- SCC compliance posture export or Cloud Asset Inventory + Policy Analyzer output
- Target framework: CIS GCP v2.0 / SOC 2 / HIPAA / PCI-DSS v4.0

**Output**:
- Pass/Fail per control with evidence
- Compliance score per domain (IAM, Logging, Networking, Compute, Storage, etc.)
- Gap list ranked by risk and remediation effort
- Quick Wins vs Long-Term remediation matrix
- Organization Policy constraints to automate compliance enforcement

**Claude's Role**: Explains each GCP control gap in context, writes remediation steps as executable runbooks with `gcloud` commands, generates compliance narratives for auditors.

**Monetization**: Enterprise — $199/mo

---

## 💡 GCP Security Pack — Cross-Skill Features

| Feature | Description |
|---|---|
| **Ask Claude** | Natural-language follow-up on any finding |
| **Google Chat / Slack Alert** | Real-time critical finding notifications |
| **Jira/Linear Ticket** | Auto-generate remediation tickets |
| **BigQuery Findings Sink** | Store all findings in your BigQuery dataset |
| **PR Review Comment** | GitHub-formatted IaC finding comments |
| **Evidence Package** | Audit-ready evidence bundle for compliance |

---

## 📦 GCP Security Pack Pricing

| Tier | Price | Includes |
|---|---|---|
| Free | $0 | Skill 3 (Storage Auditor), 3 scans/mo |
| Security | $49/mo | Skills 1–5 + Audit Log Detector |
| Enterprise | $199/mo | All skills + Compliance + API + White-label |

---

## 🛠️ Tech Stack

- **LLM**: Claude (claude-3-5-sonnet for detection, claude-3-opus for compliance)
- **Data Sources**: Cloud Asset Inventory, Security Command Center, Cloud Audit Logs, IAM Policy Analyzer, VPC Firewall Rules API
- **Frameworks**: CIS GCP v2.0, SOC 2, HIPAA, PCI-DSS v4.0, MITRE ATT&CK Cloud
- **Output**: Markdown, JSON, PDF evidence packages
- **Integrations**: Slack, Google Chat, Jira, BigQuery, PagerDuty, Chronicle SIEM
