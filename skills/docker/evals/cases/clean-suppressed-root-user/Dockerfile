# Fixture: would trigger CICD-DOCK-002 but the risk is suppressed with a reason.
# Should produce ZERO findings — the suppression must be honored. Matches the
# exact documented convention in docker/SKILL.md's Suppression section: the
# ignore comment sits directly above the USER root line it excuses.
FROM gcr.io/distroless/nodejs20-debian12:nonroot

WORKDIR /app
COPY --chown=nonroot:nonroot dist/ ./dist/
COPY --chown=nonroot:nonroot node_modules/ ./node_modules/

# docker-skill:ignore CICD-DOCK-002 -- distroless nonroot base sets UID downstream
USER root
EXPOSE 8080
HEALTHCHECK CMD ["/nodejs/bin/node", "healthcheck.js"]
CMD ["dist/server.js"]
