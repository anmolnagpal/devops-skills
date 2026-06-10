# Fixture: multiple BLOCKING + ADVISORY violations. Not a real image.
FROM node:latest

# Secret baked into a layer
ENV API_TOKEN=PLACEHOLDER_FAKE_NOT_A_SECRET

# Remote ADD instead of COPY + checksum
ADD https://example.com/tool.sh /usr/local/bin/tool.sh

# Unpinned packages, no --no-install-recommends, cache not cleaned
RUN apt-get update && apt-get install -y curl jq

# Code copied before deps — cache-busting; single stage ships build tooling
COPY . .
RUN npm install

# Shell form — SIGTERM will not reach node
CMD node dist/server.js
