# clean-gitops-pinned-appset

Nothing may fire. This case exists to stop each rule at the exclusion that bounds
it, so any finding here is a false positive.

- `CICD-GITOPS-001` — the template's `targetRevision` is `{{revision}}`, which a
  naive check reads as unpinned. Two of the three generator elements are tags
  (`v2.7.1`, `v2.7.0`); only dev tracks `main`, which is exclusion 1. The
  suppression comment states exactly that, and carries a reason, so
  `META-SUP-001` must not fire either.
- `CICD-GITOPS-002` — the AppProject names two repos and three explicit
  cluster/namespace pairs, with an empty `clusterResourceWhitelist` and a
  namespace whitelist limited to three kinds. No wildcards.
- `CICD-GITOPS-003` — prune is on but guarded three ways: `allowEmpty: false`,
  `PruneLast=true`, and `PrunePropagationPolicy=foreground`.
- `CICD-GITOPS-004` — `sync-wave: "1"` is set, and this is a leaf workload with no
  CRDs.
- `CICD-GITOPS-005` — `selfHeal: true`.
- `CICD-GITOPS-006` — one ApplicationSet, three Applications at runtime, one per
  environment with its own revision, cluster, and overlay path. Exclusion 6.
- `SEC-SEC-001` — no Secret manifests anywhere in the fixture.
- `OBS-MON-002` — `argocd-notifications-cm` defines sync-failed and
  health-degraded triggers with a subscription to a real Slack channel and
  PagerDuty service. The alerting path terminates in a human, which is the same
  standard the observability skill applies.

Note that prod runs `v2.7.0` while staging runs `v2.7.1`. That is a promotion in
progress, not a finding: this skill does not grade which revision an environment
should be on.
