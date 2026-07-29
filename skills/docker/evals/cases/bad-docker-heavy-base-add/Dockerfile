# Node service on a full Debian base, with ADD used as a COPY.
FROM node:24.11.0-bookworm AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY . .
RUN npm run build

FROM node:24.11.0-bookworm
WORKDIR /app
RUN groupadd -r app && useradd -r -g app -u 10001 app
ADD --chown=app:app ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
COPY --from=build --chown=app:app /app/dist /app/dist
COPY --from=build --chown=app:app /app/node_modules /app/node_modules
USER app
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["node", "dist/server.js"]
