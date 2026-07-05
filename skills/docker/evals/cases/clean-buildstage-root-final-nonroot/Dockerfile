# Fixture: builder stage runs as root (default, never overridden), but the
# final runtime stage runs as non-root. Should produce ZERO findings —
# FP-exclusion #1 (docker/SKILL.md): CICD-DOCK-002 targets the stage that
# actually ships and runs, not intermediate build stages.
FROM golang:1.22-bookworm AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /out/app ./cmd/app

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /out/app /app
USER nonroot:nonroot
EXPOSE 8080
HEALTHCHECK CMD ["/app", "-healthcheck"]
ENTRYPOINT ["/app"]
