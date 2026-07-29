# bad-gitops-head-prune

Twelve lines of YAML, three blocking-or-advisory findings, and every one of them
is a default someone left in place rather than a mistake they made.

- `CICD-GITOPS-001` — `targetRevision: HEAD` on a prod Application. During an
  incident, "what revision is deployed" has no answer beyond "whatever merged
  last". Exclusion 1 does not apply: destination is prod, and there is no
  ImageUpdateAutomation or Image Updater writing a pinned digest back to Git.
- `CICD-GITOPS-003` — `prune: true` with `allowEmpty: true` and no sync window,
  no `PruneLast`, no `dependsOn`. If `deploy/overlays/prod` ever renders empty
  (moved path, failed generator, bad kustomization), the controller deletes every
  resource in the `checkout` namespace and considers that a successful sync.
- `CICD-GITOPS-005` — `selfHeal: false` with automated sync. Console edits survive
  indefinitely, so the cluster drifts from Git quietly until some unrelated sync
  overwrites the hand-fix at an unpredictable moment.

Must NOT fire: `CICD-GITOPS-002` (this is an Application, not an AppProject; the
project is named `payments` rather than `default`, and the project definition is
not in this fixture, so there is nothing to conclude about its grants),
`CICD-GITOPS-004` (single flat Application, no CRDs, no app-of-apps tree, which is
exclusion 4), `CICD-GITOPS-006` (the path is a single prod overlay and the
destination is one namespace on one cluster).
