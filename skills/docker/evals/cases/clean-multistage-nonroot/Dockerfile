# Fixture: should produce ZERO findings.
FROM node:20.11-alpine3.19 AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit

FROM node:20.11-alpine3.19 AS runner
WORKDIR /app
RUN addgroup -g 1001 -S app && adduser -S app -u 1001
USER app
COPY --from=deps --chown=app:app /app/node_modules ./node_modules
COPY --chown=app:app . .
ENV NODE_ENV=production
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/server.js"]
