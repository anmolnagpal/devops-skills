# Fixture: would trigger CICD-DOCK-002 but the risk is suppressed with a reason.
# Should produce ZERO findings — the suppression must be honored.
FROM gcr.io/distroless/nodejs20-debian12:nonroot

WORKDIR /app
COPY --chown=nonroot:nonroot dist/ ./dist/
COPY --chown=nonroot:nonroot node_modules/ ./node_modules/

# docker-skill:ignore CICD-DOCK-002 -- distroless nonroot base sets UID downstream; USER is inherited from FROM, not redeclared
EXPOSE 8080
HEALTHCHECK CMD ["/nodejs/bin/node", "healthcheck.js"]
CMD ["dist/server.js"]
