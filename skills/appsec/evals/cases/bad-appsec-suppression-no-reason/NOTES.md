# bad-appsec-suppression-no-reason

The suppression convention's failure mode. `appsec-skill:ignore SEC-APP-002` with
no `-- reason` is an unreasoned waiver, so two findings fire and neither is
optional:

- `META-SUP-001` for the malformed suppression itself.
- `SEC-APP-002` for the wildcard CORS with `credentials: true`, because a
  suppression missing its reason does not suppress anything.

That second expectation is the whole point of this case. If a skill honors the
comment and stays silent on the underlying rule, an attacker (or a hurried
colleague) silences any finding in the catalog by typing eight characters and no
justification. The clean suppression cases in this suite prove the convention
works; this one proves it cannot be abused.
