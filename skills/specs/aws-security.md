# AWS Security Skills
> OpenClaw.ai + Claude | Sellable Skill Pack

---

## Skill 1 — AWS IAM Policy Auditor

**What it does**: Deep-audit IAM policies, roles, users, and permission boundaries for over-privilege, dangerous patterns, and least-privilege violations.

**Input**:
- IAM policy JSON (inline or managed) or full IAM export via `aws iam get-account-authorization-details`

**Output**:
- Risk-scored findings per policy (Critical / High / Medium / Low)
- Specific violations:
  - Wildcard actions (`"Action": "*"`)
  - Wildcard resources (`"Resource": "*"`)
  - `iam:PassRole` without condition
  - `sts:AssumeRole` with overly broad trust
  - Admin-equivalent permissions outside of designated roles
  - Unused permissions (cross-referenced with Access Analyzer)
- Safer policy replacement (least-privilege diff)
- MITRE ATT&CK mapping for high-risk permissions (e.g. Privilege Escalation, Credential Access)

**Claude's Role**: Explains each risky permission in plain English, maps to real attack scenarios, generates corrected IAM policy JSON with comments.

**2025 Threat Context**: IAM misconfiguration is the #1 initial access vector in AWS breaches. Credential theft + over-privileged roles = full account takeover.

**Monetization**: Security — $49/mo

---

## Skill 2 — AWS Security Group & Network Exposure Auditor

**What it does**: Audit EC2 Security Groups, NACLs, and VPC configurations for dangerous network exposure.

**Input**:
- Security Group JSON export or AWS account access (read-only)
- VPC and subnet configuration

**Output**:
- Critical findings:
  - `0.0.0.0/0` ingress on SSH (22), RDP (3389), database ports (3306, 5432, 1433, 27017)
  - Management ports open to internet
  - Overly broad CIDR ranges on sensitive ports
  - Unused security groups (orphaned, not attached to any resource)
- Blast radius estimate per exposed rule
- Corrected security group rules (tightened CIDR + port)
- AWS Config rule recommendations for continuous monitoring

**Claude's Role**: Explains attack surface for each open rule, generates replacement security group JSON, writes remediation runbook.

**Monetization**: Security — $49/mo

---

## Skill 3 — AWS S3 Bucket Exposure Auditor

**What it does**: Identify publicly accessible S3 buckets, dangerous ACLs, and misconfigured bucket policies before data exfiltration occurs.

**Input**:
- S3 bucket list + policy JSON + ACL export
- Account-level S3 Block Public Access settings

**Output**:
- Publicly accessible buckets (Read / Write / List)
- Buckets with disabled Block Public Access at account or bucket level
- Dangerous bucket policies (s3:GetObject with `"Principal": "*"`)
- Buckets lacking server-side encryption
- Buckets without access logging enabled
- Buckets without versioning (ransomware risk)
- Estimated data exposure risk per bucket (based on naming/tagging)

**Claude's Role**: Assesses business risk of each exposure (e.g. "This bucket name suggests PII/financial data"), generates hardened bucket policy JSON, writes incident-style exposure report.

**Monetization**: Security — $49/mo

---

## Skill 4 — AWS CloudTrail Threat Detector

**What it does**: Analyze CloudTrail logs for suspicious patterns, unauthorized changes, and MITRE ATT&CK-mapped attack indicators.

**Input**:
- CloudTrail log export (JSON, last N hours/days)
- Optional: GuardDuty findings for correlation

**Output**:
- Flagged high-risk events:
  - Root account usage
  - IAM privilege escalation sequences
  - Failed API calls (brute force / recon indicators)
  - Unusual cross-account `AssumeRole` activity
  - Security Group or IAM changes from unusual IPs/regions
  - CloudTrail or GuardDuty disabling attempts
  - S3 data exfiltration patterns (mass GetObject from unknown IP)
- MITRE ATT&CK technique mapping per finding
- Incident timeline reconstruction
- Immediate containment recommendations

**Claude's Role**: Narrates the attack sequence in plain English, generates incident response checklist, writes executive breach summary.

**Monetization**: Security — $49/mo

---

## Skill 5 — AWS Secrets & Credential Exposure Scanner

**What it does**: Detect hardcoded secrets, exposed API keys, and misconfigured credential stores in IaC, code, and configuration files.

**Input**:
- Terraform files, CloudFormation templates, CDK code
- Environment files, Kubernetes manifests, Lambda environment variables export
- GitHub repository scan (optional)

**Output**:
- File + line-level findings per secret type:
  - AWS Access Key IDs
  - AWS Secret Access Keys
  - Database connection strings
  - API keys (Stripe, Twilio, SendGrid, etc.)
  - Private SSH/TLS keys
  - JWT secrets
- Severity and blast radius per exposure
- AWS Secrets Manager / Parameter Store migration guide per secret
- Git history scan recommendation if secrets found in committed files

**Claude's Role**: Classifies each secret type, estimates blast radius if compromised, writes migration plan to AWS Secrets Manager with code snippets.

**Monetization**: Security — $49/mo

---

## Skill 6 — AWS Terraform / IaC Security Reviewer

**What it does**: Review Terraform plans or HCL modules for security misconfigurations before `terraform apply` — shift-left security for AWS infrastructure.

**Input**:
- `terraform plan` JSON output or `.tf` files
- AWS provider resources (EC2, S3, RDS, IAM, Lambda, EKS, etc.)

**Output**:
- Security findings ranked by severity:
  - S3 buckets without encryption or versioning
  - RDS instances with `publicly_accessible = true`
  - Security groups with `0.0.0.0/0` ingress
  - IAM roles with `*` actions
  - EC2 instances without IMDSv2 enforcement
  - KMS key deletion windows too short
  - Lambda functions with over-privileged execution roles
- Line-level corrected HCL code snippets
- CIS AWS Benchmark control mapping per finding

**Claude's Role**: Explains the real-world risk of each misconfiguration, generates corrected Terraform code, writes PR review comment in GitHub-ready format.

**Monetization**: Security — $49/mo

---

## Skill 7 — AWS Compliance Gap Analyzer

**What it does**: Map your AWS environment against CIS AWS Foundations Benchmark, SOC 2, HIPAA, or PCI-DSS controls and generate a prioritized remediation roadmap.

**Input**:
- AWS Config snapshot, Security Hub findings export, or account access (read-only)
- Target framework: CIS AWS v2.0 / SOC 2 / HIPAA / PCI-DSS v4.0

**Output**:
- Pass/Fail per control with evidence
- Compliance score per domain (IAM, Logging, Networking, Data Protection, etc.)
- Gap list ranked by risk and remediation effort
- Remediation priority matrix (Quick Wins vs Long-Term Projects)
- AWS Config rule recommendations to automate ongoing compliance

**Claude's Role**: Explains each control in your specific AWS context, writes remediation steps as executable runbooks, generates evidence narratives for auditors.

**Monetization**: Enterprise — $199/mo

---

## Skill 8 — AWS GuardDuty Finding Explainer & Responder

**What it does**: When GuardDuty fires findings, instantly translate them into plain-English incident summaries with actionable response steps.

**Input**:
- GuardDuty finding JSON (via EventBridge / SNS webhook)
- Optional: related CloudTrail events and VPC Flow Logs

**Output**:
- Plain-English explanation of what happened and why it's dangerous
- Attack technique identified (MITRE ATT&CK)
- Severity context: is this a real threat or false positive?
- Immediate containment steps (isolate instance, revoke credentials, etc.)
- Investigation checklist
- Slack/PagerDuty-ready incident summary

**Claude's Role**: Transforms raw GuardDuty JSON into an incident narrative, assesses false positive likelihood, generates response playbook.

**2025 Notes**: Covers GuardDuty EKS Protection, S3 Protection, RDS Protection, Lambda Protection, and Malware Protection findings.

**Monetization**: Security — $49/mo

---

## 💡 AWS Security Pack — Cross-Skill Features

| Feature | Description |
|---|---|
| **Ask Claude** | Natural-language follow-up on any finding |
| **PagerDuty / OpsGenie** | Auto-create incidents from critical findings |
| **Jira/Linear Ticket** | Auto-generate remediation tickets |
| **Slack Alert** | Real-time critical finding notifications |
| **PR Review Comment** | GitHub-formatted IaC finding comments |
| **Evidence Package** | Audit-ready evidence bundle for compliance |

---

## 📦 AWS Security Pack Pricing

| Tier | Price | Includes |
|---|---|---|
| Free | $0 | Skill 5 (Secrets Scanner), 3 scans/mo |
| Security | $49/mo | Skills 1–6, 8 |
| Enterprise | $199/mo | All skills + Compliance + API + White-label |

---

## 🛠️ Tech Stack

- **LLM**: Claude (claude-3-5-sonnet for detection, claude-3-opus for compliance reports)
- **Data Sources**: CloudTrail, GuardDuty, Security Hub, AWS Config, IAM Access Analyzer, VPC Flow Logs
- **Frameworks**: CIS AWS v2.0, SOC 2, HIPAA, PCI-DSS v4.0, MITRE ATT&CK Cloud
- **Output**: Markdown, JSON, PDF evidence packages
- **Integrations**: Slack, PagerDuty, OpsGenie, Jira, GitHub PR comments
