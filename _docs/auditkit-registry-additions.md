# Rule IDs owed to auditkit's registry

The `/docker`, `/github-actions`, and `/k8s` skills emit findings using
**auditkit's canonical rule-ID registry** (`.claude/rules/rule-ids.md` in
`clouddrove-ci/auditkit`) so inline review and deep audit share one vocabulary.

Some checks these skills make have **no existing auditkit ID**. They are listed
below and must be **added to auditkit's `rule-ids.md`** so the registry stays the
single source of truth. Until then, these IDs live only in devops-skills.

Apply this as a separate PR in the `auditkit` repo.

## CI/CD — Docker (`CICD-DOCK-*`)

auditkit already has `001` (:latest), `002` (root), `003` (no multi-stage). Add:

- `CICD-DOCK-004` — `ADD` with a remote URL (unverified fetch)
- `CICD-DOCK-005` — package install without `--no-install-recommends`
- `CICD-DOCK-006` — shell-form `CMD`/`ENTRYPOINT` (signals don't reach PID 1)
- `CICD-DOCK-007` — `ADD` used where `COPY` suffices
- `CICD-DOCK-008` — OS packages installed unpinned
- `CICD-DOCK-009` — layer order invalidates build cache
- `CICD-DOCK-010` — heavy base image where slim/distroless fits
- `CICD-DOCK-011` — package cache not cleaned in the same `RUN`
- `CICD-DOCK-012` — no `HEALTHCHECK`
- `CICD-DOCK-013` — no `.dockerignore`
- `CICD-DOCK-014` — compose `privileged`/host network without cause
- `CICD-DOCK-015` — compose service missing `restart:` policy
- `CICD-DOCK-016` — `depends_on` without `condition: service_healthy`

## CI/CD — workflows (`CICD-SEC-*`, `CICD-OPS-*`, `CICD-PERM-*`)

Reused: `CICD-PIN-001`, `CICD-PERM-001`, `CICD-SEC-001`, `CICD-FLOW-002`,
`CICD-SCAN-001`, `SEC-IAM-002`. Add:

- `CICD-SEC-002` — `pull_request_target` checking out PR head (RCE)
- `CICD-SEC-003` — script injection: `${{ github.event.* }}` in `run:`
- `CICD-SEC-004` — self-hosted runner on public repo without fork restriction
- `CICD-OPS-001` — no `concurrency` group
- `CICD-OPS-002` — job missing `timeout-minutes`
- `CICD-OPS-003` — no caching for known tool installs
- `CICD-OPS-004` — matrix without `fail-fast: false`
- `CICD-OPS-005` — duplicated workflow logic not extracted to `workflow_call`
- `CICD-PERM-002` — no `permissions: contents: read` baseline declared

## Kubernetes / Security (`SEC-K8S-*`, `ARCH-*`, `COST-K8S-*`)

Reused: `SEC-SEC-001`, `SEC-IAM-002`, `CICD-DOCK-001` (mutable image tag),
`COST-K8S-001` (no requests/limits), `COST-TAG-001` (labels). Add:

- `SEC-K8S-001` — pod `securityContext` missing/incomplete
- `ARCH-HA-003` — readiness/liveness probe missing
- `ARCH-SPOF-002` — `replicaCount < 2` for staging/prod
- `COST-K8S-003` — memory limit less than memory request

## Cross-cutting (`META-*`)

- `META-SUP-001` — inline suppression (`<skill>:ignore <ID>`) missing a `-- reason`

## Terraform (`TF-*`) — second batch (pending)

The `/tf` skill reuses auditkit's existing `TF-*` series (`TF-VAR-001/002`,
`TF-PROV-001/002`, `TF-STATE-001/002`, `TF-RES-001`, `TF-MOD-001/002`,
`TF-QUAL-001`). Four checks have no existing entry — add in a follow-up auditkit PR:

- `TF-VAR-003` — `variable` block missing `description` or explicit `type`
- `TF-VAR-004` — hardcoded env-specific value (region/account/ARN/env/CIDR) outside a `backend` block
- `TF-OUT-001` — `output` block missing `description`
- `TF-OUT-002` — output exposing a secret not marked `sensitive = true`

> The first batch (CICD-DOCK/SEC/OPS/PERM, SEC-K8S, ARCH, COST-K8S, META) merged
> in clouddrove-ci/auditkit#8. These four are the only registry debt remaining.

## Mappings to review (debatable taxonomy)

Flag for human review when applying to auditkit — these placements are judgment calls:

- K8s required labels → `COST-TAG-001` (tags drive cost-allocation + ownership; but
  `team`/`env` labels are also ops standards — consider a `STD-*` domain).
- K8s memory-limit-below-request → `COST-K8S-003` (grouped with k8s resource specs,
  though it's a correctness bug more than a cost issue).
- GHA "no CodeQL/Dependabot/dep-review" → `CICD-SCAN-001` (SAST); could split into
  `CICD-SCAN-002` (dependency scanning) for the Dependabot half.
