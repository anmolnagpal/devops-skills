---
name: github-actions
description: "GitHub Actions workflow review, scaffolding, and security hardening. Use when user says 'review my workflow', 'check my actions', 'scaffold a workflow', 'is my CI correct', 'pin actions', 'OIDC to AWS', or when working in .github/workflows/*.yml files."
metadata:
  version: 0.1.0
  author: Anmol Nagpal
  category: devops
  updated: 2026-05-14
paths:
  - "**/.github/workflows/*.yml"
  - "**/.github/workflows/*.yaml"
  - "**/.github/actions/**/*.yml"
  - "**/.github/actions/**/*.yaml"
allowed-tools:
  - Glob
  - Read
---

# GitHub Actions Skill

Review GitHub Actions workflows for security and correctness, or scaffold new workflows for Terraform, Helm/EKS, container builds, and release automation — enforcing team standards for least-privilege tokens, OIDC, and production gates.

## Keywords
github, actions, workflow, workflows, ci, cd, gha, github-actions, oidc, openid, federated, GITHUB_TOKEN, permissions, environment, environments, protection rules, reusable workflow, matrix, runner, runs-on, composite, secrets, artifacts, cache, dependabot, codeql, container, ghcr, ECR, terraform plan, helm deploy

## Output Artifacts

| Request | Output |
|---------|--------|
| `/github-actions review` | Blocking + advisory findings for `.github/workflows/*.yml` |
| `/github-actions new terraform` | Workflow with fmt/validate/plan/apply, OIDC to AWS, env protection |
| `/github-actions new docker` | Build + push to GHCR/ECR with provenance, SBOM, OIDC |
| `/github-actions new release` | Tag-driven release with changelog and artifact upload |
| `/github-actions harden` | Pin actions to SHA, set minimal `permissions:`, add OIDC, remove static AWS keys |

---

## TRIGGER — Decide what to do

1. If the user message names a mode (`review`, `new`, `harden`) → execute that.
2. Otherwise inspect the working directory:
   - If `.github/workflows/*.yml` exists → go to **REVIEW**
   - If no workflows but `.tf` or `Dockerfile` exists → ask: "No workflows found. Scaffold a **new** one? (terraform / docker / release)"
   - Otherwise ask: "What do you need? **review** / **new** / **harden**"

Always read every workflow file before commenting. Follow all `uses:` references to reusable workflows in the same repo and read those too.

---

## REVIEW — Security and correctness checks

Read the workflow(s) and produce findings in this format:

```
BLOCKING — Must fix before merge
[path:line] Issue → recommendation

ADVISORY — Should fix
[path:line] Issue → recommendation

Summary: X blocking issue(s), Y advisory issue(s).
```

### Blocking issues

1. **Untrusted action without SHA pin** — `uses: actions/checkout@v4` → pin to immutable SHA: `actions/checkout@<sha40>  # v4.2.2`. Tags are mutable.
2. **`pull_request_target` with checkout of PR head** — RCE risk. Use `pull_request` or never check out untrusted code with elevated permissions.
3. **`permissions: write-all`** — over-privileged token. Set least-privilege at job or workflow level.
4. **Static AWS credentials** — `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` in secrets for cloud auth → switch to OIDC via `aws-actions/configure-aws-credentials` with `role-to-assume`.
5. **Secret in `run:` block** — `echo $SECRET` or `env:` exposed in logs without masking → use job-level `env:` with `secrets.*`, never `echo`.
6. **Production deploy without environment protection** — `environment: production` missing or no required reviewers → add environment with required reviewers.
7. **`run:` script injection** — interpolating `${{ github.event.* }}` directly into shell → use an `env:` mapping then reference `$VAR`.
8. **Self-hosted runner on public repo without restriction** — fork PRs can run arbitrary code on your infra. Use `default: pull_request_target` controls or ephemeral runners only.

### Advisory issues

1. Concurrency missing — `concurrency: { group: ${{ github.workflow }}-${{ github.ref }}, cancel-in-progress: true }` to prevent overlapping runs.
2. No `timeout-minutes` on jobs → add 10–30 min default.
3. Caching missing for known tool installs (Terraform, npm, pip, Go modules) → use `actions/cache` or tool-specific cache actions.
4. Matrix without `fail-fast: false` for independent OS/version combinations.
5. No CodeQL / Dependabot / dependency review configured for an active repo.
6. Workflow not reusable — repeated 50+ lines across files → extract to `.github/workflows/_reusable-*.yml` with `workflow_call`.
7. Missing `contents: read` baseline — start every workflow with `permissions: contents: read` then escalate per-job.

### Example output

```
BLOCKING — Must fix before merge
[.github/workflows/deploy.yml:14] Action not pinned: uses actions/checkout@v4 → pin to immutable SHA
[.github/workflows/deploy.yml:31] Static AWS keys: secrets.AWS_ACCESS_KEY_ID → switch to OIDC via aws-actions/configure-aws-credentials with role-to-assume
[.github/workflows/deploy.yml:52] Production deploy missing environment protection → add environment: production with required reviewers
[.github/workflows/deploy.yml:67] Script injection risk: ${{ github.event.head_commit.message }} interpolated directly into run: → move to env: mapping and reference $COMMIT_MSG

ADVISORY — Should fix
[.github/workflows/deploy.yml:1] No concurrency group → add concurrency to prevent overlapping runs
[.github/workflows/deploy.yml:8] permissions: not declared → add `permissions: contents: read` baseline

Summary: 4 blocking issue(s), 2 advisory issue(s).
```

---

## NEW — Scaffold a new workflow

Ask which template:

- **terraform** — fmt / validate / plan on PR, apply on merge with environment gate
- **docker** — build + push (GHCR or ECR) with provenance and SBOM
- **release** — tag-driven changelog + artifact upload

### Terraform scaffold

Generate `.github/workflows/terraform.yml`:

```yaml
name: terraform
on:
  pull_request:
    paths: ["**/*.tf", "**/*.tfvars"]
  push:
    branches: [main]
    paths: ["**/*.tf", "**/*.tfvars"]

permissions:
  contents: read
  pull-requests: write
  id-token: write   # OIDC

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  validate:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@<sha40>  # v4.x
      - uses: hashicorp/setup-terraform@<sha40>  # v3.x
        with: { terraform_version: "1.9.x" }
      - run: terraform fmt -check -recursive
      - run: terraform init -backend=false
      - run: terraform validate

  plan:
    needs: validate
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@<sha40>  # v4.x
      - uses: aws-actions/configure-aws-credentials@<sha40>  # v4.x
        with:
          role-to-assume: arn:aws:iam::${{ vars.AWS_ACCOUNT_ID }}:role/gha-terraform-plan
          aws-region: ${{ vars.AWS_REGION }}
      - uses: hashicorp/setup-terraform@<sha40>  # v3.x
        with: { terraform_version: "1.9.x" }
      - run: terraform init
      - run: terraform plan -out=tfplan
      - uses: actions/upload-artifact@<sha40>  # v4.x
        with: { name: tfplan, path: tfplan, retention-days: 7 }

  apply:
    needs: validate
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    timeout-minutes: 30
    environment: production   # add required reviewers in repo settings
    steps:
      - uses: actions/checkout@<sha40>  # v4.x
      - uses: aws-actions/configure-aws-credentials@<sha40>  # v4.x
        with:
          role-to-assume: arn:aws:iam::${{ vars.AWS_ACCOUNT_ID }}:role/gha-terraform-apply
          aws-region: ${{ vars.AWS_REGION }}
      - uses: hashicorp/setup-terraform@<sha40>  # v3.x
        with: { terraform_version: "1.9.x" }
      - run: terraform init
      - run: terraform apply -auto-approve
```

Tell the user to:
1. Replace `<sha40>` with the SHA of the action version you want (run `gh api repos/<org>/<repo>/git/refs/tags/v4.2.2`)
2. Create IAM roles `gha-terraform-plan` (read-only) and `gha-terraform-apply` (write) with OIDC trust policy for `repo:<org>/<repo>:*`
3. Set repo vars `AWS_ACCOUNT_ID` and `AWS_REGION`
4. In repo Settings → Environments, create `production` with required reviewers

### Docker scaffold (GHCR + OIDC)

Generate `.github/workflows/docker.yml`:

```yaml
name: docker
on:
  push:
    branches: [main]
    tags: ["v*"]
  pull_request:
    paths: ["Dockerfile", ".dockerignore"]

permissions:
  contents: read
  packages: write
  id-token: write
  attestations: write

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@<sha40>  # v4.x
      - uses: docker/setup-buildx-action@<sha40>  # v3.x
      - uses: docker/login-action@<sha40>  # v3.x
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - id: meta
        uses: docker/metadata-action@<sha40>  # v5.x
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=sha
      - id: build
        uses: docker/build-push-action@<sha40>  # v6.x
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          provenance: true
          sbom: true
      - if: github.event_name != 'pull_request'
        uses: actions/attest-build-provenance@<sha40>  # v1.x
        with:
          subject-name: ghcr.io/${{ github.repository }}
          subject-digest: ${{ steps.build.outputs.digest }}
          push-to-registry: true
```

### Release scaffold

Generate `.github/workflows/release.yml` triggered on tag push, runs `gh release create` with auto-generated notes and uploads artifacts.

---

## HARDEN — Apply security baseline

Walk the workflow files and propose patches for:

1. Pin every `uses: action@vN` → `uses: action@<sha40>  # vN.M.P`. Suggest `pinact` or `actionlint` to automate.
2. Add `permissions: contents: read` at top, then escalate per-job to least needed.
3. Replace static AWS keys with OIDC + `role-to-assume`. Provide the trust policy snippet:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Federated": "arn:aws:iam::<account>:oidc-provider/token.actions.githubusercontent.com" },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
      "StringLike":  { "token.actions.githubusercontent.com:sub": "repo:<org>/<repo>:*" }
    }
  }]
}
```

4. Add `concurrency:` and `timeout-minutes:`.
5. Move secrets out of `run:` interpolation into `env:` mappings.
6. For production jobs: require `environment:` with reviewers.
7. Suggest enabling Dependabot, CodeQL, and `dependency-review-action` on PRs.

Output as a unified diff or per-file edit list, never silently rewrite.

---

## Notes for Claude

- Never invent action SHAs — tell the user to look them up with `gh api repos/<owner>/<repo>/git/refs/tags/<tag>`.
- Reusable workflows belong in `.github/workflows/_<name>.yml` (underscore prefix is convention).
- For self-hosted runners, prefer ephemeral (Actions Runner Controller on Kubernetes) over persistent.
- Composite actions in `.github/actions/<name>/action.yml` need their own review pass.
