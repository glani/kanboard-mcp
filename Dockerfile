# =============================================================================
# Multi-Stage Dockerfile for Kanboard MCP Server
# Supports multiple transport modes: stdio, SSE, Streamable HTTP
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Builder
# This stage compiles the Go application for the target platform
# -----------------------------------------------------------------------------
FROM golang:1.24-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata file

# Set the working directory
WORKDIR /build

# Copy go mod files first for better caching
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the source code
COPY . .

# Set build arguments for cross-compilation
ARG TARGETOS=linux
ARG TARGETARCH=amd64
ARG VERSION=dev
ARG BUILD_TIME

# Build the application
# -s -w: Strip debug info for smaller binary
# -X: Inject version and build time information
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build \
    -ldflags="-s -w -X main.version=${VERSION} -X main.buildTime=${BUILD_TIME}" \
    -a -installsuffix cgo \
    -o kanboard-mcp .

# Verify the binary was created
RUN ls -lh kanboard-mcp && file kanboard-mcp

# -----------------------------------------------------------------------------
# Stage 2: Runtime Image
# Alpine-based image for full transport support (stdio, SSE, HTTP)
# -----------------------------------------------------------------------------
FROM alpine:3.21 AS runtime

# Add labels for container metadata
LABEL org.opencontainers.image.title="Kanboard MCP Server" \
      org.opencontainers.image.description="MCP server for Kanboard integration with multi-transport support" \
      org.opencontainers.image.source="https://github.com/bivex/kanboard-mcp" \
      org.opencontainers.image.vendor="Bivex"

# Install runtime dependencies
RUN apk add --no-cache ca-certificates tzdata wget

# Create app directory
WORKDIR /app

# Copy the binary from builder
COPY --from=builder /build/kanboard-mcp /kanboard-mcp

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy config file if exists
COPY mcp-tools-config.yaml /app/mcp-tools-config.yaml

# Environment variables for transport configuration
ENV MCP_MODE=stdio \
    MCP_PORT=8080

# Expose port for HTTP/SSE transports
EXPOSE 8080

# Health check (only effective for HTTP/SSE modes)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD if [ "$MCP_MODE" != "stdio" ]; then wget --no-verbose --tries=1 --spider http://localhost:${MCP_PORT}/health 2>/dev/null || exit 1; else exit 0; fi

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# -----------------------------------------------------------------------------
# Stage 3: Minimal Runtime (scratch-based for stdio only)
# Use this for minimal image size when only stdio transport is needed
# -----------------------------------------------------------------------------
FROM scratch AS runtime-minimal

# Copy the binary from builder
COPY --from=builder /build/kanboard-mcp /kanboard-mcp

# Copy CA certificates from builder
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Set the entrypoint
ENTRYPOINT ["/kanboard-mcp"]

# -----------------------------------------------------------------------------
# Stage 4: Export
# This stage holds only the artifacts for local export
# Uses FROM scratch to minimize the exported content
# -----------------------------------------------------------------------------
FROM scratch AS export

# Copy the binary from builder stage
COPY --from=builder /build/kanboard-mcp /kanboard-mcp

# Copy CA certificates if needed for runtime
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy timezone data if needed
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# No entrypoint - this is just for artifact export
