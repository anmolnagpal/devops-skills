For the Tier-2 behavioral run: `npm audit --omit=dev --json` against this
lockfile reports `lodash@4.17.15` as vulnerable to CVE-2020-8203 (prototype
pollution) and CVE-2021-23337 (command injection), both patched in `4.17.21`.
Record or mock that output rather than requiring live registry access in CI.

`package.json`/`package-lock.json` here are named with a `.fixture` suffix
(not the real filenames) so GitHub's dependency graph / Dependabot security
updates don't parse this intentionally-vulnerable version and open a real
bump PR against it (this happened once — see PR history). When running the
Tier-2 harness or testing manually, copy/symlink them to their real names in
a scratch directory first.
