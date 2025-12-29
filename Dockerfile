# =============================================================================
# Multi-Stage Dockerfile for Kanboard MCP Server
# Implements the Builder Pattern with Local Export
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
# Stage 2: Runtime Image (Optional)
# Minimal image to run the application if needed
# -----------------------------------------------------------------------------
FROM scratch AS runtime

# Copy the binary from builder
COPY --from=builder /build/kanboard-mcp /kanboard-mcp

# Copy CA certificates from builder
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Set the entrypoint
ENTRYPOINT ["/kanboard-mcp"]

# -----------------------------------------------------------------------------
# Stage 3: Export
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

