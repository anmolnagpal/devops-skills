# bad-ci-shared-job-static-keys

Four rules with no prior fixture in this suite, on a pipeline that has clearly had
some care applied: `when: manual` on deploy, `--atomic` on helm, an explicit
`--namespace`, a pinned runner image, `helm lint` in validate, and the image tag
passed as a variable.

- `CICD-SEC-001` and `SEC-IAM-002` — a literal AWS access key pair sits in the
  top-level `variables:` block. Two findings, not one: the secret is hardcoded in
  pipeline YAML, and the mechanism itself is wrong because static keys are used where
  OIDC role federation belongs. Both are BLOCKING and they have different fixes, so
  reporting only one leaves the other undone.
- `SEC-SEC-001` — `kubeconfig-prod.yaml` is committed in the repo, complete with a
  cluster endpoint, CA data, and a user token, and the deploy job points `KUBECONFIG`
  at it. It must come from a masked CI variable.
- `CICD-FLOW-003` — one `deploy` job serves both staging and production by switching
  on `$TARGET_ENV`, including in `environment.name` and the helm `--namespace`. There
  is no separation, so a mistyped variable deploys staging's artifact to prod under
  prod's credentials.
- `TF-STATE-001` — `terraform init` runs with no backend configuration anywhere in
  the repo and no `-backend-config` flag, so the pipeline holds state locally in the
  job workspace and discards it when the runner is reclaimed.

Must NOT fire: `CICD-FLOW-002` (deploy is `when: manual`, so the gate exists even
though the job is wrong in other ways), `CICD-HELM-001` (`helm lint` runs in
validate), `CICD-HELM-002` (`--atomic` present), `CICD-HELM-003` (`--namespace`
present), `CICD-HELM-004` (tag comes from `$CI_COMMIT_SHA`), `CICD-DOCK-001` (runner
image pinned to 1.14.3), `CICD-FLOW-004` (an `environment:` block is present).

`terraform apply -auto-approve` here must NOT raise `CICD-FLOW-002` on its own: the
rule's `-auto-approve` clause is about an ungated prod apply, and this job is gated
manually. The real defect on that line is the shared-environment problem above.
