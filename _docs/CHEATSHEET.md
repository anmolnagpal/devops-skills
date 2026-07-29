# Claude Code Cheatsheet

Real example prompts for every skill, plugin, and MCP server in this repo.

---

## Tips

> **Command namespacing** — these skills ship as the `clouddrove` plugin, so in Claude Code the slash commands are namespaced: `/clouddrove:tf`, `/clouddrove:k8s`, etc. Examples below use the short `/tf` form for brevity — prefix with `clouddrove:` when typing them.

**Auto-trigger** — skills activate automatically when you open relevant files. You don't need to type the skill name:
- `*.tf` / `*.tfvars` → `/tf` (or `/clouddrove:wrapper-tf` if the repo has an `_modules/` directory)
- `values.yaml`, `Chart.yaml`, Helm templates → `/k8s`
- `.gitlab-ci.yml` → `/ci`
- `.github/workflows/*.yml` → `/github-actions`
- `CODEOWNERS`, `.github/dependabot.yml`, PR/issue templates → `/github`
- `Dockerfile`, `docker-compose*.yml` → `/docker`
- `_modules/**/*.tf`, `environments/**/*.tf`, `.github/workflows/terraform.yml` → `/clouddrove:wrapper-tf`

**Which Terraform skill?** Two skills cover Terraform — pick one per repo:
- `/tf` — generic Terraform / `terraform-aws-modules` ecosystem
- `/clouddrove:wrapper-tf` — repo wraps `clouddrove/*/aws` modules under `_modules/` (team standard)

Don't mix them in the same repo — they give conflicting recommendations.

**CLAUDE.md** — copy `templates/CLAUDE.md` into your project repo and fill in the placeholders. Claude will have permanent context about your AWS setup, Terraform backend, and EKS clusters without you needing to explain it every session.

---

## Skills

### `/tf` — Terraform

```
/tf review
/tf review                          # Claude reads your .tf files and checks everything
/tf new lambda                      # Scaffold a new Lambda module
/tf new rds                         # Scaffold a new RDS module
/tf new eks                         # Scaffold a new EKS cluster module
/tf new vpc                         # Scaffold a new VPC
/tf new s3                          # Scaffold an S3 bucket module
/tf new iam-role                    # Scaffold an IAM role
/tf upgrade                         # Guide upgrading Terraform or AWS provider version
```

**Example conversations:**
```
"Review my Terraform before I raise an MR"
"Scaffold a Lambda called image-processor, Python 3.12, 512MB, needs VPC access"
"I need to upgrade from AWS provider 4.x to 5.x — what will break?"
"Check all .tf files in this directory for hardcoded values"
```

---

### `/k8s` — Kubernetes / EKS

```
/k8s review                         # Review values.yaml before deploying
/k8s review prod                    # Review with production-level strictness
/k8s new payments-api               # Scaffold values.yaml for a new service
```

**Example conversations:**
```
"Review my Helm values before I deploy to staging"
"Scaffold a production-ready values.yaml for a background worker service"
"Check if my values.yaml has any hardcoded secrets or missing resource limits"
"Create Helm values for an HTTP service called checkout-api, medium resources, port 8080"
```

---

### `/clouddrove:wrapper-tf` — Team Standard for CloudDrove Wrapper Repos

Use on any repo where `_modules/<name>/` wraps `clouddrove/<name>/aws`. Supersedes `/tf` on these repos.

```
/clouddrove:wrapper-tf new monitoring       # Scaffold _modules/monitoring/ with module "labels" + standard vars
/clouddrove:wrapper-tf new vpc              # Scaffold _modules/vpc/
/clouddrove:wrapper-tf ci                   # Generate .github/workflows/terraform.yml + drift.yml
/clouddrove:wrapper-tf review               # Pre-PR check: wrapper pattern, naming, CloudDrove gotchas, security baseline
/clouddrove:wrapper-tf controls             # SOC2 CC6/CC7/C1/A1 + GDPR Art.5/25/32/33 coverage table
```

**Example conversations:**
```
"Scaffold a new _modules/secrets module following our wrapper pattern"
"Generate the Terraform GitHub Actions CI for this repo — three sequential apply jobs"
"Review my PR for wrapper-pattern violations and CloudDrove gotchas (waf_scop, label_order, ACM/DNS ordering)"
"Produce the SOC2 control coverage table for the audit"
"Patch the .terraform/modules vpc/waf/karpenter .region bug after terraform init"
```

---

### `/ci` — GitLab CI/CD

```
/ci review                          # Review .gitlab-ci.yml for issues
/ci new terraform                   # Scaffold a Terraform pipeline
/ci new helm                        # Scaffold a Helm/EKS deploy pipeline
```

**Example conversations:**
```
"Review my GitLab pipeline — is there anything blocking or unsafe?"
"Scaffold a GitLab CI pipeline for a Terraform repo with staging and prod environments"
"Scaffold a Helm deploy pipeline for the payments-api service"
"Does my pipeline have a manual gate on production? Is the image pinned?"
```

---

### `/github-actions` — GitHub Actions Workflows

```
/github-actions review              # Review .github/workflows/*.yml for security and best practices
/github-actions new terraform       # Scaffold a Terraform workflow with OIDC and PR gates
/github-actions new docker          # Scaffold a Docker build/push workflow
```

**Example conversations:**
```
"Review my GitHub Actions workflow — are actions pinned, is OIDC used, are permissions minimal?"
"Migrate this workflow from long-lived AWS keys to OIDC"
"Scaffold a workflow that runs tflint, checkov, and posts plan output as a PR comment"
"Why is this workflow leaking secrets in the logs?"
```

---

### `/github` — Repo Hygiene

```
/github audit                       # Audit repo settings: branch protection, CODEOWNERS, dependabot, releases
/github new codeowners              # Scaffold a CODEOWNERS file
/github new dependabot              # Scaffold .github/dependabot.yml
```

**Example conversations:**
```
"Audit this repo's GitHub settings against our team baseline"
"Set up branch protection on main with required reviews and status checks"
"Add CODEOWNERS so the platform team owns _modules/ and CI workflows"
"Configure dependabot for terraform, github-actions, and docker"
```

---

### `/docker` — Dockerfile / Compose

```
/docker review                      # Review Dockerfile for size, security, layering issues
/docker new node                    # Scaffold a multi-stage Node Dockerfile
/docker new python                  # Scaffold a Python Dockerfile with a slim base
/docker new go                      # Scaffold a distroless Go Dockerfile
```

**Example conversations:**
```
"Review my Dockerfile — is it minimal, multi-stage, and running as non-root?"
"Shrink this image — it's 1.2GB and should be under 200MB"
"Pin all base images by digest, not tag"
"Review docker-compose.yml for production-readiness"
```

---

### `/finops` — AWS Cost Optimization

```
/finops review                      # Identify cost waste in the current account
/finops eks                         # EKS-specific cost analysis (right-sizing, Karpenter, Spot)
/finops savings                     # Savings Plans + Reserved Instance recommendations
```

**Example conversations:**
```
"Find our top 5 cost-waste sources this month"
"Right-size EC2 and RDS based on Compute Optimizer recommendations"
"Should we buy a Savings Plan? Show the break-even"
"Where is data transfer cost coming from?"
"Audit unattached EBS volumes, old snapshots, and idle load balancers"
```

---

### `/owasp-security` — Security Review

**Example conversations:**
```
"Review this code for security vulnerabilities"
"Is this authentication implementation secure?"
"Check this API endpoint for injection risks"
"Review how we're storing secrets in this service"
"Is this Terraform IAM policy following least privilege?"
"What OWASP risks apply to this Lambda function?"
"Show me the secure pattern for password storage in Python"
"What are the security risks specific to Go?"
"Review this AI agent code for agentic security risks"
"What ASVS Level 2 requirements apply to this service?"
```

**Deep-dive references** (ask Claude to read these for detailed guidance):
```
"Read owasp/languages.md and check this Ruby code for security issues"
"Read owasp/agentic.md and review this agent architecture"
"Read owasp/secure-patterns.md and show me the safe error handling pattern"
```

---

### `/clouddrove:tf-plan` — Terraform Plan Review

Run `terraform plan -out=tfplan && terraform show -json tfplan > tfplan.json`
first. The skill reads the artifact; it never runs Terraform itself.

**Example conversations:**
```
"Review tfplan.json before I apply this"
"Is this plan safe to apply to prod?"
"What will this plan destroy?"
"Why is it replacing aws_db_instance.main?"
"Check this plan for drift"
"Does my pipeline apply the same plan it reviewed?"
```

---

### `/clouddrove:gitops` — Argo CD / Flux

**Example conversations:**
```
"Review my Argo CD Applications"
"Why did Argo delete my resources?"
"Check this AppProject for over-granted access"
"Review my app-of-apps sync wave ordering"
"Set up GitOps for the checkout service"
"Review my Flux Kustomizations"
"Is my targetRevision safe for prod?"
```

---

### `/clouddrove:observability` — Monitoring, Alerting, SLOs

**Example conversations:**
```
"Review my monitoring setup"
"Am I flying blind on this service?"
"Do my alerts actually reach anyone?"
"Review my alertmanager routes"
"Write alert rules for the checkout API"
"Define an SLO for payments-api"
"Check my log retention"
"Set up burn-rate alerts"
```

---

### `/clouddrove:incident` — Runbooks, On-call, Postmortems

**Example conversations:**
```
"Write a runbook for the checkout API"
"Review my runbooks"
"Are we ready to put this service on-call?"
"Define severity levels for our team"
"Which alerts are missing runbooks?"
"Write a postmortem from this timeline"
"Review this postmortem for blameless language"
```

---

### `/skill-creator` — Build a New Skill

**Example conversations:**
```
"Help me build a new skill for writing runbooks"
"I want to create a skill that reviews Dockerfile best practices"
"Build and test a new /cost skill for AWS cost analysis"
```

---

## MCP Servers

### `kubernetes-mcp-server` — Live Kubernetes Access

```
"List all pods in the production namespace"
"Show me pods that are not in Running state"
"Get the logs for the payments-api pod"
"What events have happened in the last hour in namespace staging?"
"List all Helm releases across namespaces"
"Show me which pods have no resource limits set"
"What's the status of the ingress in production?"
```

---

### `eks-mcp-server` — AWS EKS (AWS-native)

```
"What's the status of our EKS cluster?"
"Show me recent CloudWatch errors for the payments-api deployment"
"Are there any nodes in NotReady state?"
"What IAM roles are associated with service accounts in production?"
"Show me the EKS cluster add-ons and their versions"
"Any recent cluster autoscaler events I should know about?"
"Diagnose why the checkout-service keeps restarting"
```

---

### `billing-mcp-server` — AWS Cost & Billing

```
"What's our total AWS spend this month?"
"Show me cost breakdown by service for the last 30 days"
"Which service has the biggest cost increase compared to last month?"
"Are we on track to stay within budget this month?"
"What EC2 instances does Compute Optimizer recommend rightsizing?"
"Show me our biggest savings opportunities — reserved instances or savings plans"
"How much are we spending on data transfer?"
"Break down costs by environment tag (prod vs staging vs dev)"
```

---

### `mcp-atlassian` — Jira

```
"Show me all open tickets assigned to me"
"What tickets are in the INFRA project with status In Progress?"
"Create a Jira ticket: upgrade EKS to 1.32, team DevOps, priority high"
"Add a comment to INFRA-123: deployed to staging, monitoring for 24h"
"Search for all P1 bugs opened this week"
"Move INFRA-456 to Done"
"Show me everything in the current sprint for the DevOps team"
"What tickets are blocked right now?"
"Create a ticket for the Terraform AWS provider upgrade we discussed"
```

> Use your Jira instance URL and personal access token when setting up the MCP server.

---

## Plugins

### `terraform-code-generation@hashicorp`

These skills trigger automatically when working with Terraform. You can also invoke them directly:

```
"Generate Terraform code for an S3 bucket with versioning enabled"
"Search the Terraform registry for an RDS module"
"Import this existing AWS resource into Terraform"
"Write a Terraform test for this module"
"Does this code follow the HashiCorp Terraform style guide?"
```

### `terraform-module-generation@hashicorp`

```
"Refactor this Terraform code into a reusable module"
"Help me create a Terraform Stack for multi-environment deployments"
```

### `claude-mem@thedotmack`

```
/mem-search terraform backend       # Search past decisions about Terraform backends
/mem-search eks cluster             # Find past context about EKS setup
"Remember that we use eu-west-1 as our primary region"
"What did we decide about the VPC CIDR ranges?"
"Save this — we use terraform-aws-modules/eks ~> 20.0 for all EKS clusters"
```

### `superpowers` (obra/superpowers)

```
/brainstorming                      # Socratic session to nail requirements before coding
/tdd                                # Red-green-refactor TDD cycle with failing tests first
/debug                              # Systematic 4-phase debugging (hypothesis → root cause → fix)
/execute-plan                       # Run a plan as batched subagents with code review checkpoints
```

**Example conversations:**
```
"Before I build this, let's brainstorm the right approach"
"Write the failing test first, then implement the Lambda handler"
"I've tried fixing this 3 times — use /debug to find the actual root cause"
"Execute this plan using subagents and review the output before merging"
```

### `engineering-workflow-skills@mhattingpete`

```
"Commit and push these changes with a conventional commit message"
"Push this to remote"
"Review this code before I push"
"Help me plan this feature before I start coding"
```

---

## Combining Skills + MCP

The real power is combining them:

```
"Check the Jira ticket INFRA-234 and then review the Terraform in this directory
 to see if the implementation matches what was requested"

"Look at the failing pod logs in production, diagnose the issue,
 and create a Jira ticket with your findings"

"Check our AWS costs this month, identify the biggest driver,
 and scaffold a Terraform change to address it"

"Review my Helm values for staging and create a Jira ticket
 for each blocking issue you find"
```
