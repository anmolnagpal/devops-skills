# CLAUDE.md — Project Context

<!--
  INSTRUCTIONS FOR SETUP:
  1. Copy this file to the root of your project repo
  2. Fill in all <PLACEHOLDER> values for your project
  3. Remove sections that don't apply
  4. Add to .gitignore: CLAUDE.local.md (for personal overrides)
  5. Commit this file so the whole team benefits

  This file is auto-loaded by Claude Code every session.
  Keep it focused — only include what Claude can't infer from the code itself.
-->

## Git workflow (MUST follow)

1. Never push directly to `main` / `master` / `trunk`. Always work on a branch and open a pull request.
2. No `Co-Authored-By` trailers, no "🤖 Generated with …" footers, no AI attribution in commits or PR descriptions.
3. Use the repo's `git config user.name` / `user.email`. Do not override per-commit identity.
4. One logical change per branch / PR. No bundled unrelated edits.
5. Before pushing, summarize the commit + diff stat and ask the user to confirm.
6. Never `--force` push to a shared branch.

## Project

- **Service:** <SERVICE_NAME> — <one-line description>
- **Team:** <TEAM_NAME>
- **Repo:** https://github.com/<org>/<repo>

## AWS

- **Primary region:** eu-west-1
- **AWS profile (local):** <AWS_PROFILE_NAME>
- **Account ID (staging):** <STAGING_ACCOUNT_ID>
- **Account ID (prod):** <PROD_ACCOUNT_ID>

## Terraform

- **State backend bucket:** <S3_BUCKET_NAME>
- **State lock table:** <DYNAMODB_TABLE_NAME>
- **State key pattern:** `<service>/<environment>/terraform.tfstate`
- **Required Terraform version:** `~> 1.7`
- **Required AWS provider:** `~> 5.0`

When scaffolding or reviewing Terraform, always use these backend values.

## Kubernetes / EKS

- **Cluster name (staging):** <EKS_CLUSTER_NAME_STAGING>
- **Cluster name (prod):** <EKS_CLUSTER_NAME_PROD>
- **Default namespace:** <NAMESPACE>
- **ECR registry:** <ACCOUNT_ID>.dkr.ecr.eu-west-1.amazonaws.com

## GitLab CI/CD

- **CI AWS variable (key):** AWS_ACCESS_KEY_ID
- **CI AWS variable (secret):** AWS_SECRET_ACCESS_KEY
- **Kubeconfig variable (staging):** KUBECONFIG_STAGING
- **Kubeconfig variable (prod):** KUBECONFIG_PROD
- **Default branch:** main

## Team Conventions

- All Terraform resources must have tags: `Name`, `Environment`, `Team`, `ManagedBy = "terraform"`
- Module versions pinned with `~>` — never floating or git refs
- No `-auto-approve` in any pipeline
- Production jobs always require `when: manual`
- Secrets via AWS Secrets Manager + external-secrets operator (never inline in values.yaml)

## What NOT to do

- Never hardcode AWS account IDs, ARNs, or region strings
- Never commit `.tfstate`, `.tfvars` with real values, or kubeconfig files
- Never use `latest` as an image tag in any Helm values file
- Never merge to main without a passing pipeline

## Claude Code Permissions

<!-- These are enforced via .claude/settings.json in this repo. Copy that file too. -->

Always allowed (read-only, safe):
- `kubectl get/describe/logs`
- `terraform plan/validate`
- `git log/diff/status`

Always denied (destructive, require human confirmation):
- `kubectl delete` — never auto-delete resources
- `kubectl exec` — no shell access into pods
- `terraform apply` — no auto-apply, always manual

## Jira

- **Project key:** <JIRA_PROJECT_KEY>
- **Board:** https://<your-org>.atlassian.net/jira/software/projects/<JIRA_PROJECT_KEY>/boards
