# Azure Security Skills
> OpenClaw.ai + Claude | Sellable Skill Pack

---

## Skill 1 — Azure Entra ID (IAM) Auditor

**What it does**: Audit Microsoft Entra ID (formerly Azure AD) for over-privileged roles, dangerous access patterns, and identity security gaps.

**Input**:
- Entra ID role assignments export (via Microsoft Graph API or CSV)
- Conditional Access policies export (optional)
- PIM configuration (optional)

**Output**:
- Risk-scored findings:
  - Permanent Global Administrator assignments (should use PIM)
  - Excessive privileged roles (Owner, Contributor) assigned at subscription scope
  - No MFA enforced on privileged accounts
  - Legacy authentication protocols not blocked
  - Guest accounts with excessive permissions
  - App registrations with dangerous API permissions (e.g. `Directory.ReadWrite.All`)
  - Service principals with secret credentials vs certificate credentials
- Conditional Access policy gaps (missing MFA enforcement, no location restrictions)
- PIM adoption recommendations per role
- MITRE ATT&CK mapping (Persistence, Privilege Escalation, Defense Evasion)

**Claude's Role**: Explains each identity risk in plain English, maps to real attack scenarios (e.g. "This allows full tenant takeover"), generates Conditional Access policy JSON and PIM configuration recommendations.

**2025 Threat Context**: Entra ID compromise is the top Azure breach vector. Phishing-resistant MFA (FIDO2/passkeys) is the 2025 standard — skill flags accounts not meeting this bar.

**Monetization**: Security — $49/mo

---

## Skill 2 — Azure Network Security Group (NSG) & Firewall Auditor

**What it does**: Audit Azure NSG rules, Azure Firewall policies, and network architecture for dangerous internet exposure and lateral movement risks.

**Input**:
- NSG rules export (JSON) or Azure subscription access (read-only)
- Azure Firewall policy (optional)
- VNet and subnet topology

**Output**:
- Critical findings:
  - NSG rules with `0.0.0.0/0` source on RDP (3389), SSH (22), database ports
  - Management ports (WinRM, PowerShell Remoting) open to internet
  - Overly permissive inbound rules allowing entire RFC-1918 ranges
  - Missing NSG on subnets containing sensitive resources
  - Default "Allow All" rules not overridden
  - NSG flow logs disabled (no visibility for incident response)
- Blast radius estimate per exposure
- Corrected NSG rule JSON (tightened source CIDR + ports)
- Just-in-Time (JIT) VM Access enablement recommendations

**Claude's Role**: Explains attack surface for each dangerous rule, generates replacement NSG JSON, writes remediation runbook with Azure CLI commands.

**Monetization**: Security — $49/mo

---

## Skill 3 — Azure Storage & Blob Exposure Auditor

**What it does**: Identify publicly accessible Azure Storage accounts, containers with anonymous read access, and misconfigured blob policies.

**Input**:
- Storage account list + access tier + public access settings
- Azure Defender for Storage findings (optional)

**Output**:
- Public storage accounts (anonymous blob read/list access)
- Storage accounts not requiring HTTPS
- Storage accounts with shared access keys not rotated (> 90 days)
- Storage accounts lacking private endpoint (accessible via public internet)
- Missing soft delete configuration (ransomware risk)
- Containers with public access enabled
- SAS tokens with excessive permissions or no expiry

**Claude's Role**: Assesses data risk per storage account (naming/tagging heuristic), generates hardened storage account policy ARM/Bicep template, writes exposure risk narrative.

**Monetization**: Security — $49/mo

---

## Skill 4 — Microsoft Defender for Cloud Posture Reviewer

**What it does**: Interpret Microsoft Defender for Cloud Secure Score findings and generate a prioritized remediation roadmap with actionable fixes.

**Input**:
- Defender for Cloud Secure Score export or API access
- Current score and recommendation list

**Output**:
- Secure Score breakdown by control domain
- Top 10 quick wins (highest score impact, lowest effort)
- Critical findings with immediate risk:
  - MFA not enabled on accounts
  - Vulnerabilities on VMs (OS + app patching)
  - SQL databases not encrypted at rest
  - Azure Key Vault not configured for soft delete
  - Defender plans not enabled for key workload types
- Effort-vs-impact remediation matrix
- Azure Policy enforcement recommendations for automated compliance

**Claude's Role**: Prioritizes findings by real-world risk vs score-gaming, generates step-by-step remediation guides, writes security posture narrative for CISO/board reporting.

**2025 Notes**: Covers new Defender CSPM features: attack path analysis, cloud security graph, and data security posture management (DSPM).

**Monetization**: Security — $49/mo

---

## Skill 5 — Azure Key Vault & Secrets Security Auditor

**What it does**: Audit Azure Key Vault configuration, access policies, and secret hygiene for credential exposure and misconfiguration risks.

**Input**:
- Key Vault list + access policies / RBAC roles + network rules
- Secret/key/certificate inventory (names and metadata, not values)

**Output**:
- Key Vaults with public network access enabled (no firewall or private endpoint)
- Key Vaults using legacy Access Policies instead of RBAC
- Over-privileged access (accounts with full Key Vault access vs targeted permissions)
- Expired or near-expiry certificates and secrets
- Secrets not rotated in > 90 days
- Missing soft delete and purge protection (deletion attack risk)
- Key Vault diagnostic logging disabled
- App secrets stored in App Service config instead of Key Vault references

**Claude's Role**: Explains each risk in plain English (e.g. "Public network access means any internet user can attempt to access your secrets"), generates hardened Key Vault Bicep template, writes secret rotation plan.

**Monetization**: Security — $49/mo

---

## Skill 6 — Azure Terraform / IaC Security Reviewer

**What it does**: Review Terraform plans or Bicep/ARM templates for Azure security misconfigurations before deployment — shift-left security.

**Input**:
- `terraform plan` JSON output or `.tf` files targeting `azurerm` provider
- Bicep or ARM template files (optional)

**Output**:
- Security findings ranked by severity:
  - Storage accounts with `allow_blob_public_access = true`
  - SQL databases with `public_network_access_enabled = true`
  - VMs without disk encryption
  - Key Vaults without soft delete and purge protection
  - NSGs with `0.0.0.0/0` ingress rules
  - Managed identities not used (hardcoded credentials)
  - Log Analytics workspace with short retention
- Line-level corrected HCL/Bicep snippets
- CIS Azure Benchmark control mapping per finding

**Claude's Role**: Explains the real-world risk of each misconfiguration in Azure context, generates corrected Terraform/Bicep code, writes PR review comment in GitHub-ready format.

**Monetization**: Security — $49/mo

---

## Skill 7 — Azure Activity Log & Sentinel Threat Detector

**What it does**: Analyze Azure Activity Logs and Microsoft Sentinel alerts for suspicious patterns, unauthorized changes, and attack indicators.

**Input**:
- Azure Activity Log export (JSON, last N hours/days)
- Microsoft Sentinel incidents export (optional)

**Output**:
- Flagged high-risk events:
  - Subscription-level role assignment changes
  - Azure Policy or Defender disabling attempts
  - Mass resource deletions
  - Unusual cross-tenant access patterns
  - Key Vault access from unexpected locations
  - Entra ID role elevation outside business hours
  - Failed login storms (brute force indicators)
- MITRE ATT&CK technique mapping
- Incident timeline reconstruction
- Immediate containment steps

**Claude's Role**: Narrates the attack sequence, assesses false positive likelihood, generates incident response playbook, writes executive breach summary.

**Monetization**: Security — $49/mo

---

## Skill 8 — Azure Compliance Gap Analyzer

**What it does**: Map your Azure environment against CIS Azure Foundations Benchmark, SOC 2, ISO 27001, or HIPAA controls and generate a prioritized remediation roadmap.

**Input**:
- Defender for Cloud compliance report export or Azure Policy compliance state
- Target framework: CIS Azure v2.0 / SOC 2 / ISO 27001 / HIPAA / PCI-DSS v4.0

**Output**:
- Pass/Fail per control with evidence
- Compliance score per domain
- Gap list ranked by risk and remediation effort
- Quick Wins vs Long-Term remediation matrix
- Azure Policy initiative recommendations for automated compliance

**Claude's Role**: Explains each control gap in your specific Azure context, writes remediation steps as runbooks, generates compliance narratives for auditors and assessors.

**Monetization**: Enterprise — $199/mo

---

## 💡 Azure Security Pack — Cross-Skill Features

| Feature | Description |
|---|---|
| **Ask Claude** | Natural-language follow-up on any finding |
| **Microsoft Teams Alert** | Real-time critical finding notifications |
| **Azure DevOps Work Item** | Auto-generate remediation work items |
| **Sentinel Playbook Trigger** | Auto-trigger Logic App playbooks on findings |
| **Evidence Package** | Audit-ready evidence bundle |
| **PR Review Comment** | GitHub/ADO-formatted IaC finding comments |

---

## 📦 Azure Security Pack Pricing

| Tier | Price | Includes |
|---|---|---|
| Free | $0 | Skill 5 (Key Vault Auditor), 3 scans/mo |
| Security | $49/mo | Skills 1–6 + Activity Log Detector |
| Enterprise | $199/mo | All skills + Compliance + API + White-label |

---

## 🛠️ Tech Stack

- **LLM**: Claude (claude-3-5-sonnet for detection, claude-3-opus for compliance)
- **Data Sources**: Microsoft Graph API, Defender for Cloud, Azure Activity Log, Sentinel, Azure Policy, Key Vault
- **Frameworks**: CIS Azure v2.0, SOC 2, ISO 27001, HIPAA, PCI-DSS v4.0, MITRE ATT&CK Cloud
- **Output**: Markdown, JSON, PDF evidence packages
- **Integrations**: Microsoft Teams, Azure DevOps, Jira, Sentinel, PagerDuty
