---
name: tf
description: "Generic Terraform review, scaffolding, and version upgrades for AWS infrastructure using the terraform-aws-modules ecosystem. Use when user says 'review my terraform', 'before I raise an MR', 'scaffold a lambda/rds/s3/eks/vpc', 'check my .tf files', 'upgrade provider', or when working in .tf or .tfvars files. NOTE: if the repo has an `_modules/` directory wrapping `clouddrove/*/aws` modules, use /clouddrove-tf instead — the two patterns conflict."
metadata:
  version: 1.1.0
  author: Anmol Nagpal
  category: devops
  updated: 2026-04-16
paths:
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.tfvars.example"
allowed-tools:
  - Glob
  - Read
---

# Terraform Skill

Review Terraform code before MRs, scaffold new AWS resources, or guide safe version upgrades — all enforcing team standards.

## Keywords
terraform, tf, hcl, aws, infrastructure, iac, module, provider, variables, outputs, backend, s3, state, plan, apply, MR, review, upgrade, lambda, rds, s3, eks, vpc, iam

## Output Artifacts

| Request | Output |
|---------|--------|
| `/tf review` | Blocking / advisory issue list with file:line references |
| `/tf new <resource>` | `variables.tf`, `main.tf`, `outputs.tf`, `versions.tf`, `terraform.tfvars.example` |
| `/tf upgrade` | Breaking change analysis + numbered upgrade checklist |

---

## Step 1 — Determine the action

Read the arguments provided:

- `review` → go to **REVIEW**
- `new <resource-type>` → go to **NEW**
- `upgrade` → go to **UPGRADE**
- No arguments → read the current directory using Glob, then decide:
  - If `.tf` files exist → ask: "I can see Terraform files here. What do you need? **review** (pre-MR check) / **new** (scaffold a resource) / **upgrade** (version bump guide)"
  - If the directory is empty → default to **NEW** and ask what resource to create

---

## REVIEW — Pre-MR Terraform Check

Run before every MR. Read all `.tf` files in the current directory and subdirectories, then check every item below.

### Variables
- Every `variable` block must have a non-empty `description`
- Every `variable` block must have an explicit `type` — never rely on type inference
- Never use a hardcoded environment-specific value as a `default` (e.g. `default = "eu-west-1"`)
- Use `sensitive = true` on variables that hold secrets, passwords, or tokens

### Outputs
- Every `output` block must have a non-empty `description`
- Any output exposing a password, secret, key, token, or credential must have `sensitive = true`

### No hardcoded values
Never hardcode the following in resource or module blocks — always use variables:
- AWS region strings (e.g. `"eu-west-1"`, `"us-east-1"`)
- AWS account IDs (12-digit numbers)
- ARNs (strings starting with `arn:aws:`)
- Credentials, passwords, tokens, or API keys
- Environment names (e.g. `"prod"`, `"staging"`)
- IP addresses or CIDR blocks that differ between environments

### Terraform and provider versions
Always include a `terraform {}` block:

```hcl
terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    # bucket         = "your-tfstate-bucket"
    # key            = "<service>/terraform.tfstate"
    # region         = "eu-west-1"
    # dynamodb_table = "terraform-state-lock"
    # encrypt        = true
  }
}
```

- Use `~>` for all version constraints — never `>=` alone or unpinned
- `required_version` must always be set

### Remote backend
- Always configure a remote backend — never use local state in shared repos
- Use S3 backend with a `dynamodb_table` for state locking

### Tagging
Always define a `locals` block with common tags and merge into every resource and module:

```hcl
locals {
  common_tags = {
    Name        = var.name
    Environment = var.environment
    Team        = var.team
    ManagedBy   = "terraform"
  }
}
```

All four tags are required on every AWS resource: `Name`, `Environment`, `Team`, `ManagedBy = "terraform"`.

### Module usage
Prefer `terraform-aws-modules` over raw AWS provider resources:
- Lambda → `terraform-aws-modules/lambda/aws ~> 7.0`
- RDS → `terraform-aws-modules/rds/aws ~> 6.0`
- S3 → `terraform-aws-modules/s3-bucket/aws ~> 4.0`
- EKS → `terraform-aws-modules/eks/aws ~> 20.0`
- VPC → `terraform-aws-modules/vpc/aws ~> 5.0`
- IAM → `terraform-aws-modules/iam/aws ~> 5.0`

Always pin module versions with `version = "~> X.Y"` — never use a git ref, branch, or omit the version.

### Review output format

```
BLOCKING — Must fix before MR
------------------------------
[main.tf:12] Hardcoded value: region "eu-west-1" is hardcoded → move to a variable
[outputs.tf:5] Missing description on output "db_endpoint"

ADVISORY — Should fix
----------------------
[main.tf:8] Raw aws_s3_bucket used → consider terraform-aws-modules/s3-bucket/aws

Summary: 2 blocking issue(s), 1 advisory issue(s). Fix blocking issues before raising MR.
```

If the repo contains only module definitions (no root module), skip the backend check and note it.

---

## NEW — Scaffold a New Terraform Resource

### Identify the resource type
Extract from the argument (e.g. `new lambda`, `new rds`). If not provided, ask: "What resource type? (lambda / rds / s3 / eks / vpc / iam-role)"

### Ask targeted questions (max 5)

**Always ask:**
1. Resource name? (e.g. `payments-processor`)
2. Environment — fixed value or variable? (dev / staging / prod)
3. AWS region — fixed value or variable?

**Resource-specific:**
- **lambda:** Runtime? Memory (MB)? Timeout (seconds)? VPC access needed?
- **rds:** Engine (mysql/postgres)? Instance class? Multi-AZ?
- **s3:** Public or private? Versioning? Lifecycle rules?
- **eks:** Kubernetes version? Node instance type? Min/max nodes?
- **vpc:** CIDR? Number of AZs? NAT gateway?
- **iam-role:** Which service assumes this role? What permissions?

Wait for answers before generating code.

### Generated files

**`variables.tf`** — every variable has `description` and `type`

**`main.tf`** — module call using the correct `terraform-aws-modules` module with a `locals` block for tags

**`outputs.tf`** — all resource IDs, ARNs, endpoints, names; each with `description`; secrets with `sensitive = true`

**`versions.tf`**:
```hcl
terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    # bucket         = "your-tfstate-bucket"
    # key            = "<service>/<resource>/terraform.tfstate"
    # region         = "eu-west-1"
    # dynamodb_table = "terraform-state-lock"
    # encrypt        = true
  }
}
```

**`terraform.tfvars.example`** — placeholder values only, never real values

End with:
```
Next steps:
1. Fill in terraform.tfvars from terraform.tfvars.example
2. Configure the backend block in versions.tf
3. terraform init && terraform plan
4. Run /tf review before raising your MR
```

---

## UPGRADE — Safe Version Upgrade Guide

### Read the current state
Find and read `versions.tf`, all `*.tf` files with module `source` and `version`, and `.terraform.lock.hcl`. Report the current versions.

### Identify the target
If not provided, ask: "What are you upgrading, and to which version? (e.g. AWS provider 4.x → 5.x, Terraform 1.6 → 1.9)"

### Breaking changes reference

**AWS provider 4.x → 5.x:**
- `aws_s3_bucket` inline `acl`, `versioning`, `logging`, `lifecycle_rule`, `website`, `cors_rule`, `replication_configuration` → must be separate resources
- `aws_security_group` inline `ingress`/`egress` → deprecated, use `aws_security_group_rule`
- `aws_instance` IMDSv2 now required by default

**AWS provider 3.x → 4.x:**
- S3 ACL and policy resources separated
- Default tags support added

**Terraform core minor (1.x → 1.x):** Generally safe; check for deprecated function usage.

Scan `.tf` files for affected patterns and report each with file and line number.

### Upgrade checklist output

```
Upgrade Checklist: [FROM] → [TO]

Before you start
[ ] Confirm no pending terraform plan changes
[ ] Verify remote state is backed up in S3

Code changes required
[ ] <file:line> — <what to change and how>

Version bumps
[ ] Update required_version in versions.tf
[ ] Update provider version
[ ] Update module versions: <list>

Steps
1. Make code changes above
2. terraform init -upgrade
3. terraform validate
4. terraform plan — review for unexpected replacements or deletions
5. Raise MR and run /tf review
6. Apply to non-production first
7. Apply to production with a team member watching

Rollback
- Apply is transactional — if it fails, state is unchanged
- To roll back code: revert the version bump and run terraform init -upgrade again
```

Flag any resource that would be destroyed and recreated — these need manual sign-off.
Do not suggest upgrading multiple major versions in one step.
