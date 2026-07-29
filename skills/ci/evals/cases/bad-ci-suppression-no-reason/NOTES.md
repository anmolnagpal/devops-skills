# bad-ci-suppression-no-reason

`ci-skill:ignore CICD-FLOW-002` with no `-- reason` above a production deploy job
that has no `when: manual` gate.

Both findings fire: `META-SUP-001` for the unreasoned suppression, and
`CICD-FLOW-002` for the ungated prod deploy, because a suppression missing its
reason does not suppress anything.

This is the highest-stakes version of the rule. The suppression is sitting on the
one check that stops an unreviewed change reaching production, so a skill that
honors it silently is worse than a skill with no suppression support at all.

Everything else here is clean on purpose: the image is tagged with a commit SHA,
helm runs with `--atomic` and an explicit `--namespace`, and the job declares its
environment.
