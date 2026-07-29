# bad-gitops-wildcard-project

The fixture is otherwise a well-run setup, which is the point: these two findings
survive good hygiene everywhere else.

- `CICD-GITOPS-002` — the `payments` AppProject grants `sourceRepos: ["*"]`,
  `destinations` of `*`/`*`, and both resource whitelists wide open. The project
  exists to bound a tenant and bounds nothing. The description says "shared prod
  cluster", which is what rules out exclusion 2: a wildcard in a single-tenant
  cluster grants nothing new, but here it grants every other team's namespace.
  Consolidate the four wildcard fields into one finding.
- `CICD-GITOPS-004` — an app-of-apps (`directory.recurse: true`) whose children
  include cert-manager with `crds.enabled: true` and a `cluster-issuers`
  Application that creates ClusterIssuer resources. No `sync-wave` annotation on
  any of the three, so the CRDs and their consumers apply in the same pass and the
  issuers fail on first sync roughly half the time. Exclusion 4 does not apply
  precisely because CRDs are in play.

Must NOT fire, and each is a trap:

- `CICD-GITOPS-001` — every source is pinned: `v3.4.0` twice and chart `v1.19.2`.
- `CICD-GITOPS-003` — prune is on, but `allowEmpty: false` is explicit and the
  parent adds `PruneLast=true`. That is exclusion 3, a guarded prune.
- `CICD-GITOPS-005` — `selfHeal: true` throughout.
- `CICD-GITOPS-006` — one cluster, distinct namespaces per concern.
