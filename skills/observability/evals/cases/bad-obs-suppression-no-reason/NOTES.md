# bad-obs-suppression-no-reason

`observability-skill:ignore OBS-LOG-002` with no `-- reason`, on a prod log group
that has no `retention_in_days`.

Both fire: `META-SUP-001` for the unreasoned suppression and `OBS-LOG-002` for the
unbounded retention, because a suppression missing its reason does not suppress
anything.

`OBS-LOG-002` is the right rule to test this on, because it is the one rule this
skill reports even in dev. An unreasoned suppression on it is a bill that grows
for ever with a comment where the justification should be.

`clean-obs-full-stack` proves a reasoned suppression of `OBS-TRC-001` is honored
and raises nothing. This case is its inverse.
