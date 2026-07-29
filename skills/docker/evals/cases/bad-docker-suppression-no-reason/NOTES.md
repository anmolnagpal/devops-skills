# bad-docker-suppression-no-reason

`docker-skill:ignore CICD-DOCK-002` with no `-- reason` immediately above
`USER root`.

Both fire: `META-SUP-001` for the unreasoned suppression and `CICD-DOCK-002` for
the root user, because a suppression missing its reason does not suppress
anything.

Compare with this suite's clean suppression case, where the same rule is
suppressed with a real justification (a distroless base setting the UID
downstream) and correctly stays silent. The two cases together are the contract:
the convention works, and it needs a reason to work.

The rest of the Dockerfile is deliberately good so nothing else can fire:
multi-stage, pinned base image, `npm ci --omit=dev`, dependency layer before the
source copy, exec-form CMD, and a HEALTHCHECK.
