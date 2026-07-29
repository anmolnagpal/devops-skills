# bad-tfplan-suppression-no-reason

`tf-plan-skill:ignore TF-PLAN-001` with no `-- reason` in the source that produced
the plan, above a 500GB EBS volume whose plan shows a replace forced by
`availability_zone`.

Both fire: `META-SUP-001` for the unreasoned suppression and `TF-PLAN-001` for the
replacement, because a suppression missing its reason does not suppress anything.

The tags say `Purpose: settlement archive, 7-year retention`, which rules out
exclusion 1: this is not a scratch mount despite living in a file called
`scratch.tf`. Nothing in the plan or the source shows a snapshot, so exclusion 2
does not apply either. The suppression comment is the only thing standing between
this apply and the deletion of a seven-year regulatory archive, and it asserts
nothing.

This is also the case that pins the skill's suppression scope: the comment lives in
`.tf` source while the finding comes from the plan artifact, so the skill has to
read both to honor or reject a suppression at all.
