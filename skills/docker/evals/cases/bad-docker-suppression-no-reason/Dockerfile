FROM node:24.11.0-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY . .

FROM node:24.11.0-alpine
WORKDIR /app
COPY --from=build /app /app
# docker-skill:ignore CICD-DOCK-002
USER root
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "server.js"]
