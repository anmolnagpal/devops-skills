# bad-docker-heavy-base-add

Two advisory rules that had no fixture, on a Dockerfile that is otherwise a good
example. That is deliberate: both findings are the kind a reviewer waves through
because nothing is broken.

- `CICD-DOCK-007` — `ADD --chown=app:app ./entrypoint.sh ...` copies a local file
  with no tar extraction and no remote URL, so `COPY` does the same job with fewer
  implicit behaviors. Note this must NOT be reported as `CICD-DOCK-004`, which is the
  BLOCKING remote-URL form. Same instruction, different rule, different severity, and
  conflating them either over-blocks or under-reports.
- `CICD-DOCK-010` — both stages use `node:24.11.0-bookworm`, a full Debian base, for
  a service that needs no system toolchain at runtime. `-slim` or a distroless
  runtime removes most of the image and most of the CVE surface.

Must NOT fire: `CICD-DOCK-001` (base pinned to an exact version, no `latest`),
`CICD-DOCK-002` (a non-root `app` user is created and `USER app` is set before the
entrypoint), `CICD-DOCK-003` (multi-stage), `CICD-DOCK-006` (both `ENTRYPOINT` and
`CMD` are exec form), `CICD-DOCK-009` (manifests copied and dependencies installed
before `COPY . .`), `CICD-DOCK-012` (a `HEALTHCHECK` hits a real path),
`CICD-DOCK-013` (a `.dockerignore` exists and covers `.git`, `node_modules`, and
`.env`), `SEC-SEC-001` (no secrets in any layer).

`CICD-DOCK-005`, `008`, and `011` must also stay silent: there is no `apt-get` or
`apk` invocation anywhere, so recommends, pinning, and cache cleanup have nothing to
apply to. `groupadd`/`useradd` are not package installs.
