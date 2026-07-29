# bad-gitops-suppression-no-reason

`gitops-skill:ignore CICD-GITOPS-001` with no `-- reason`, above
`targetRevision: main` on a prod Application.

Both fire: `META-SUP-001` for the unreasoned suppression and `CICD-GITOPS-001` for
the mutable ref, because a suppression missing its reason does not suppress
anything.

The contrast with `clean-gitops-pinned-appset` is exact. There, the same rule is
suppressed with a reason that names why dev tracks a branch and confirms staging
and prod are pinned, and the skill must stay silent. Here the comment asserts
nothing, and the destination is prod. Same rule, same convention, opposite
outcomes, and the reason is the only difference.

Everything else is correct so no other rule fires: guarded prune (`allowEmpty:
false`, `PruneLast=true`), `selfHeal: true`, a sync wave, a named project, one
namespace on one cluster.
