# bad-appsec-committed-secrets

Two rules that were registered and emitted by nothing until now.

- `SEC-SEC-003` — a committed `.env` carrying values that are visibly real: a
  Postgres URL with an inline password, a session signing key, an SMTP password. The
  presence of one innocuous line (`FEATURE_FLAG_NEW_CHECKOUT=true`) is deliberate:
  the rule keys on the file holding real credentials, not on every variable in it.
- `SEC-SEC-004` — a committed `deploy.key` containing an `OPENSSH PRIVATE KEY` PEM
  block. The filename alone is suggestive; the PEM header is what makes it certain.

The key material here is an inert placeholder rather than a parseable key, for the
same reason the other fixtures use inert values: GitHub push protection scans this
repo, and a scanner cannot tell a fixture from a leak. The signal the skill needs is
the filename and the PEM header, and both are intact.

`server.js` is deliberately correct so nothing else fires: `helmet()` is applied, so
`SEC-APP-001` stays silent, and CORS names an explicit origin rather than a wildcard,
so `SEC-APP-002` does too.

`SEC-DEP-001` must also stay silent. The two dependencies are current, and more to
the point the rule requires output from a real audit tool: with no lockfile in this
directory there is nothing for `npm audit` to resolve, and the skill is instructed
not to guess vulnerabilities from a package name and version.
