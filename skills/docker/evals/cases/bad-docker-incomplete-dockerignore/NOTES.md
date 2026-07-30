# bad-docker-incomplete-dockerignore

The unambiguous half of `CICD-DOCK-013`, and the reason the rule did not need
dropping entirely.

A `.dockerignore` is present, so nothing has to be inferred from absence. It
excludes build noise (`dist`, `coverage`, `*.log`) and omits the three entries the
rule names: `.git`, `node_modules`, and `.env`. Each omission has a real cost.
`node_modules` alone can send hundreds of megabytes to the daemon and then be
overwritten by `npm ci` anyway; `.git` ships your whole history into the context;
`.env` is how a secret reaches a layer nobody meant to build.

`package.json` is present on purpose: it makes this directory a visible build
context root, which is what the skill's exclusion 4 requires before the absence
half of this rule may be reported. Here the file exists, so that caveat does not
apply and the finding stands on the contents alone.

Nothing else may fire. The Dockerfile is deliberately good: multi-stage, pinned
alpine base, `npm ci --omit=dev`, manifests copied before source, a non-root
`app` user with an explicit UID, exec-form `CMD`, and a `HEALTHCHECK` on a real
path. A run that reports a second finding here has over-reported.
