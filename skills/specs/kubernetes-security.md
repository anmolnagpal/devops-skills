# Kubernetes Security Skills
> OpenClaw.ai + Claude | Sellable Skill Pack | Works with EKS · AKS · GKE

---

## Skill 1 — RBAC Auditor

**What it does**: Deep-audit Kubernetes RBAC — Roles, ClusterRoles, RoleBindings, ClusterRoleBindings, and ServiceAccounts — for over-privilege and dangerous permission patterns.

**Input**:
- RBAC export (`kubectl get roles,clusterroles,rolebindings,clusterrolebindings -A -o json`)
- ServiceAccount inventory

**Output**:
- Risk-scored findings:
  - Subjects with `cluster-admin` ClusterRoleBinding (full cluster takeover risk)
  - Wildcard verbs (`["*"]`) or resources (`["*"]`) in roles
  - `pods/exec` or `pods/attach` permissions (remote code execution)
  - `secrets` GET/LIST permissions beyond required scope
  - Default ServiceAccount with non-trivial role bindings
  - `impersonate` permissions (allows privilege escalation)
  - Roles bound at cluster scope when namespace scope would suffice
- Least-privilege replacement role YAML per finding
- MITRE ATT&CK Kubernetes mapping (Privilege Escalation, Lateral Movement, Credential Access)

**Claude's Role**: Explains the real attack path each permission enables (e.g. "pods/exec on any pod = shell access to every container in cluster"), generates corrected minimal-privilege Role YAML.

**2025 Threat Context**: RBAC misconfiguration is the #1 Kubernetes privilege escalation vector. The `cluster-admin` binding is found in 40%+ of audited clusters.

**Monetization**: Security — $49/mo

---

## Skill 2 — Pod Security & Privileged Container Auditor

**What it does**: Scan all running workloads for dangerous pod security configurations that allow container escape, host access, and privilege escalation.

**Input**:
- Pod/Deployment/StatefulSet specs (`kubectl get pods -A -o json`)
- Pod Security Admission (PSA) configuration per namespace
- Kubernetes version (determines PSP vs PSA)

**Output**:
- Critical findings:
  - `privileged: true` containers (full host access)
  - `hostPID: true` / `hostNetwork: true` / `hostIPC: true`
  - `allowPrivilegeEscalation: true` (or not set — defaults to true)
  - Containers running as root (`runAsNonRoot: false` or not set)
  - Containers with dangerous Linux capabilities (`NET_ADMIN`, `SYS_ADMIN`, `SYS_PTRACE`)
  - Missing `readOnlyRootFilesystem: true`
  - Missing seccomp profile (runtime/default or custom)
  - Namespaces without PSA enforcement labels
- Corrected `securityContext` YAML per workload
- Pod Security Standards (PSS) compliance level per namespace: Privileged / Baseline / Restricted

**Claude's Role**: Explains the container escape risk for each finding, generates patched pod spec with hardened securityContext, writes namespace PSA enforcement configuration.

**Monetization**: Security — $49/mo

---

## Skill 3 — Network Policy Auditor

**What it does**: Audit Kubernetes network policies for dangerous defaults — most clusters run with zero network segmentation, making lateral movement trivial.

**Input**:
- Network Policy objects (`kubectl get networkpolicies -A -o json`)
- Pod and namespace inventory with labels
- CNI plugin type (Calico, Cilium, WeaveNet, etc.)

**Output**:
- Namespaces with no NetworkPolicy (open east-west traffic)
- Namespaces missing default-deny ingress and/or egress
- Policies with overly broad selectors (`{}` — matches all pods)
- Missing egress restrictions (pods can reach internet directly)
- Inter-namespace communication paths that should be blocked
- Service-to-service reachability matrix (who can talk to what)
- Default-deny policy YAML per namespace
- Minimal allow-list policies for common patterns (web → api → db)

**Claude's Role**: Maps the blast radius of missing network policies (e.g. "Any compromised pod in namespace X can reach your database"), generates complete default-deny + allow-list NetworkPolicy YAML.

**2025 Notes**: Cilium Network Policies (L7-aware) and Istio AuthorizationPolicies are covered in addition to standard K8s NetworkPolicy objects.

**Monetization**: Security — $49/mo

---

## Skill 4 — Container Image Security Scanner

**What it does**: Audit container images running in the cluster for critical CVEs, outdated base images, and supply chain risks.

**Input**:
- Running image inventory (`kubectl get pods -A -o jsonpath='{..image}'`)
- Image scan results (Trivy, Grype, Snyk, or ECR/ACR/GAR scan output)
- Image registry configuration

**Output**:
- Critical/High CVE findings per image with CVSS score
- Images using deprecated or EOL base images (e.g. Ubuntu 18.04, Alpine 3.12)
- Images pulled from untrusted registries (non-private registry)
- Images running as root user
- Images without image digest pinning (tag-only references — mutable, hijackable)
- Images not scanned in > 7 days
- Admission controller policy to block critical CVE images

**Claude's Role**: Prioritizes CVEs by exploitability in K8s context (not just raw CVSS), explains supply chain risk of each finding, generates OPA/Kyverno admission policy to block unsafe images.

**Monetization**: Security — $49/mo

---

## Skill 5 — Secrets Security Auditor

**What it does**: Audit how secrets are managed in Kubernetes — the most common source of credential leakage in K8s environments.

**Input**:
- Kubernetes Secret inventory (metadata only — names, namespaces, types, not values)
- Deployment/Pod specs (to detect env var secret injection patterns)
- etcd encryption configuration (if accessible)

**Output**:
- Secrets mounted as environment variables (visible in `kubectl describe`, logs, crash dumps)
- Default ServiceAccount token automounting enabled cluster-wide
- Secrets referenced in pod specs that haven't been rotated in > 90 days
- Secrets of type `kubernetes.io/dockerconfigjson` with broad registry access
- etcd encryption at rest not enabled
- Cluster without external secrets manager integration (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager)
- Secrets accessible by overly broad RBAC roles

**Claude's Role**: Explains the leak path for each finding (e.g. "Env var secrets appear in `kubectl describe pod` output — readable by anyone with pod read access"), generates External Secrets Operator configuration for migration to cloud secrets manager.

**Monetization**: Security — $49/mo

---

## Skill 6 — Kubernetes Terraform / Helm IaC Security Reviewer

**What it does**: Review Terraform (EKS/AKS/GKE cluster config) and Helm chart values for security misconfigurations before deployment.

**Input**:
- Terraform `.tf` files for `aws_eks_cluster`, `azurerm_kubernetes_cluster`, `google_container_cluster`
- Helm chart `values.yaml` files
- `helm template` rendered output (optional)

**Output**:
- Cluster-level findings:
  - Public API server endpoint enabled without IP allowlisting
  - RBAC not enabled (`enable_rbac = false`)
  - Network policy not enabled at cluster creation
  - Node auto-upgrade disabled (unpatched nodes)
  - Logging and monitoring disabled
  - Private cluster not configured
  - Workload Identity / IRSA / Workload Identity Federation not enabled
- Helm chart findings:
  - `securityContext` not set in chart defaults
  - `hostNetwork: true` in chart templates
  - Hardcoded secrets in `values.yaml`
- Corrected Terraform HCL and Helm values YAML

**Claude's Role**: Explains the risk of each cluster-level misconfiguration, generates corrected Terraform modules, writes Helm values security hardening guide.

**Monetization**: Security — $49/mo

---

## Skill 7 — Runtime Threat Detector (Falco Findings Analyzer)

**What it does**: Analyze Falco runtime security alerts and Kubernetes Audit Log events to detect active threats and attack patterns in running clusters.

**Input**:
- Falco alert stream (JSON via webhook or log export)
- Kubernetes Audit Log export (last N hours)
- Optional: cloud-native runtime alerts (GuardDuty EKS, Defender for Containers, GKE Threat Detection)

**Output**:
- Flagged high-risk events:
  - Shell spawned in container (`/bin/bash`, `/bin/sh` execution)
  - Sensitive file reads (`/etc/shadow`, `/etc/kubernetes/admin.conf`)
  - Unexpected outbound connections from pods
  - Privilege escalation attempts inside containers
  - `kubectl exec` into production pods from unusual users
  - Crypto-mining process signatures detected
  - RBAC changes during off-hours
  - Pod launched with host namespace access
- MITRE ATT&CK Containers matrix mapping
- Incident timeline reconstruction
- Immediate containment steps (isolate pod, revoke SA token, cordon node)

**Claude's Role**: Narrates the attack sequence from raw Falco/audit events, assesses false positive likelihood, generates incident response playbook with `kubectl` commands.

**Monetization**: Security — $49/mo

---

## Skill 8 — CIS Kubernetes Benchmark Compliance Analyzer

**What it does**: Assess your cluster against the CIS Kubernetes Benchmark (v1.9) and cloud-specific managed K8s benchmarks — generate a prioritized remediation roadmap.

**Input**:
- `kube-bench` output (JSON) or manual cluster configuration export
- Cloud variant: EKS / AKS / GKE benchmark version
- Kubernetes version

**Output**:
- Pass/Fail per CIS control with evidence
- Compliance score per section:
  - Control Plane (API server, controller manager, scheduler)
  - etcd
  - Control Plane Configuration
  - Worker Nodes (kubelet)
  - Policies (RBAC, PSA, Network Policies)
- Critical failures requiring immediate fix
- Quick Wins vs Long-Term remediation matrix
- Automated remediation scripts where applicable

**Claude's Role**: Explains each control failure in your specific cluster context, writes remediation steps as `kubectl` and cloud CLI commands, generates compliance narrative for auditors.

**2025 Notes**: Covers CIS EKS Benchmark v1.4, CIS AKS Benchmark v1.4, CIS GKE Benchmark v1.4 in addition to base CIS Kubernetes v1.9.

**Monetization**: Enterprise — $199/mo

---

## 💡 Kubernetes Security Pack — Cross-Skill Features

| Feature | Description |
|---|---|
| **Ask Claude** | Natural-language follow-up on any finding |
| **Slack / PagerDuty** | Real-time critical finding notifications |
| **Jira/Linear Ticket** | Auto-generate remediation tickets with YAML patches |
| **PR Review Comment** | GitHub/GitLab-formatted IaC finding comments |
| **YAML Patch Generator** | Ready-to-apply securityContext and RBAC fixes |
| **Evidence Package** | kube-bench + findings bundle for compliance audits |

---

## 📦 Kubernetes Security Pack Pricing

| Tier | Price | Includes |
|---|---|---|
| Free | $0 | Skill 5 (Secrets Auditor), 3 scans/mo |
| Security | $49/mo | Skills 1–5 + Runtime Detector |
| Enterprise | $199/mo | All skills + CIS Compliance + API + White-label |

---

## 🛠️ Tech Stack

- **LLM**: Claude (claude-3-5-sonnet for detection, claude-3-opus for compliance)
- **Data Sources**: Kubernetes API, Falco, kube-bench, Trivy/Grype, Cloud Runtime Security (GuardDuty EKS / Defender for Containers / GKE Threat Detection)
- **Frameworks**: CIS Kubernetes v1.9, CIS EKS/AKS/GKE Benchmarks, MITRE ATT&CK Containers, NSA/CISA K8s Hardening Guide
- **Output**: Markdown, JSON, YAML patches, PDF evidence packages
- **Integrations**: Slack, PagerDuty, Jira, GitHub/GitLab, ArgoCD, Falco, OPA/Gatekeeper, Kyverno
