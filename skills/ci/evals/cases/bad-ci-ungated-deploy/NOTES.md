# bad-ci-ungated-deploy

One finding, and it is a single word: `allow_failure: true` on `unit_tests`.

The pipeline has a test stage, it runs before build and deploy, and the stage order
looks like a gate. It is not. With `allow_failure: true` a failing test is reported
and the pipeline continues, so `build_image` and `deploy_prod` run against code whose
tests failed. `CICD-FLOW-001` is about a deploy that does not depend on a *passing*
test, and stage ordering alone does not provide that.

Everything else is deliberately correct so nothing else fires: `when: manual` on the
prod deploy (`CICD-FLOW-002`), an `environment:` block (`CICD-FLOW-004`), `helm lint`
before the deploy (`CICD-HELM-001`), `--atomic` (`CICD-HELM-002`), an explicit
`--namespace` (`CICD-HELM-003`), the image tag from `$CI_COMMIT_SHA` rather than
hardcoded (`CICD-HELM-004`), pinned runner images on all three jobs
(`CICD-DOCK-001`), and no hardcoded credentials anywhere (`CICD-SEC-001`,
`SEC-IAM-002`).

`CICD-FLOW-003` must also stay silent: `deploy_prod` serves one environment, named
literally rather than switched on a variable.
