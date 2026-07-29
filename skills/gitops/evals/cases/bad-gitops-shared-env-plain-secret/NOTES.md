# bad-gitops-shared-env-plain-secret

Repo-shaped, because the rendered manifests under `deploy/base/` are where two of the
four findings live and the Application alone cannot show them.

- `CICD-GITOPS-006` — one Application layers `values-staging.yaml` and
  `values-prod.yaml` over a shared `deploy/base` path, on a single shared cluster and
  one namespace. Staging and prod cannot hold different revisions, cannot be gated
  separately, and cannot be rolled back independently, which removes the main thing
  GitOps was supposed to provide. Exclusion 6 does not apply: there is no
  ApplicationSet generator and no per-overlay Kustomization, just two value files in
  one Application.
- `SEC-SEC-001` — `deploy/base/secret.yaml` commits a live Stripe key and a full
  Postgres URL with an inline password, as `stringData`, unencrypted. In a GitOps repo
  the blast radius is everyone with read access plus the entire git history. No SOPS,
  no Sealed Secrets, no external-secrets anywhere in the tree.
- `CICD-DOCK-001` — the Deployment's image is `checkout:latest`. With `selfHeal: true`
  the controller re-reconciles a mutable tag forever and no two syncs are guaranteed
  to deploy the same bytes.
- `OBS-MON-002` — no `argocd-notifications-cm`, no triggers, no subscriptions, so a
  failed or degraded sync in a payments path is silent. Contrast
  `clean-gitops-pinned-appset`, which ships exactly that ConfigMap.

Must NOT fire, and each is deliberate: `CICD-GITOPS-001` (`targetRevision: v2.7.0` is
a pinned tag), `CICD-GITOPS-002` (no AppProject in this fixture, so its grants are
unknown and must not be guessed at), `CICD-GITOPS-003` (prune is guarded by
`allowEmpty: false` and `PruneLast=true`), `CICD-GITOPS-004` (`sync-wave` is set and
there are no CRDs), `META-SUP-001` (no suppression comments anywhere).

Note the tension the fixture creates on purpose: the source ref is pinned while the
image tag is not, so the Application looks reproducible and the workload is not.
