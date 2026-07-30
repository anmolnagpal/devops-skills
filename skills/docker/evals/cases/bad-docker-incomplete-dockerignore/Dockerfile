FROM node:24.11.0-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY . .
RUN npm run build

FROM node:24.11.0-alpine
WORKDIR /app
RUN addgroup -S app && adduser -S -G app -u 10001 app
COPY --from=build --chown=app:app /app/dist /app/dist
COPY --from=build --chown=app:app /app/node_modules /app/node_modules
USER app
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/server.js"]
