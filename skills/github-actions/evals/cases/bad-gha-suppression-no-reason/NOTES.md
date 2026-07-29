# bad-gha-suppression-no-reason

`gha-skill:ignore CICD-SEC-001` with no `-- reason`, above a step that hardcodes a
deploy token in `env`.

Both fire: `META-SUP-001` for the unreasoned suppression, and `CICD-SEC-001` for
the hardcoded secret, because a suppression missing its reason does not suppress
anything. A silencable secret check is not a secret check.

This case also gives `CICD-SEC-001` its first fixture in this suite. It was in the
catalog with no eval behind it, which meant the skill could stop detecting
hardcoded workflow secrets entirely and every gate would still pass.

Everything else is deliberately correct so nothing else fires: `actions/checkout`
is SHA-pinned, `permissions` is a `contents: read` baseline, the job declares a
concurrency group, a timeout, and a production environment.
