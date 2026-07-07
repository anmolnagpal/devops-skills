For the Tier-2 behavioral run: `npm audit --omit=dev --json` against this
lockfile reports `lodash@4.17.15` as vulnerable to CVE-2020-8203 (prototype
pollution) and CVE-2021-23337 (command injection), both patched in `4.17.21`.
Record or mock that output rather than requiring live registry access in CI.
