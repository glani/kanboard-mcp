# 🐳 Docker Builder Pattern Documentation

This document explains the Docker Builder Pattern implementation for Kanboard MCP Server.

## Table of Contents

- [Overview](#overview)
- [Builder Pattern Explained](#builder-pattern-explained)
- [Multi-Stage Build Architecture](#multi-stage-build-architecture)
- [Usage](#usage)
- [Examples](#examples)
- [Artifacts](#artifacts)
- [Best Practices](#best-practices)

## Overview

This project uses modern Docker best practices with the **Builder Pattern** and **Multi-Stage Build with Local Export** to build the Kanboard MCP Server for Linux containers (amd64 and arm64 architectures).

## Builder Pattern Explained

### What is the Builder Pattern?

The Builder Pattern is a Docker build strategy that separates the build environment from the runtime environment. This approach:

1. **Reduces Image Size**: Only the runtime dependencies are included in the final image
2. **Improves Security**: No build tools (Go compiler, git, etc.) in production images
3. **Enables Cross-Compilation**: Build for different architectures from a single Dockerfile
4. **Simplifies Artifact Export**: Extract binaries directly to the host filesystem

### Multi-Stage Export

The modern implementation uses Docker BuildKit's local export feature to generate artifacts without creating a final Docker image. This is the "best practice" approach for distributing binaries.

**Key Command:**
```bash
docker build --output type=local,dest=./out .
```

## Multi-Stage Build Architecture

### Stage 1: Builder

Compiles the Go application for the target platform.

```dockerfile
FROM golang:1.24-alpine AS builder
# Install dependencies
# Download Go modules
# Compile the binary
```

**Purpose:**
- Contains all build tools (Go compiler, git, etc.)
- Compiles the statically-linked binary
- Optimized for build speed and caching

### Stage 2: Runtime (Optional)

Minimal image to run the application if you need a Docker image.

```dockerfile
FROM scratch AS runtime
COPY --from=builder /build/kanboard-mcp /kanboard-mcp
```

**Purpose:**
- Ultra-minimal base image (scratch)
- Contains only the binary and necessary certificates
- Suitable for production deployments

### Stage 3: Export

Holds only the artifacts for local export.

```dockerfile
FROM scratch AS export
COPY --from=builder /build/kanboard-mcp /kanboard-mcp
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
```

**Purpose:**
- Uses `FROM scratch` for minimal export size
- Contains binary, SSL certificates, and timezone data
- No entrypoint - this is just for artifact extraction

## Usage

### The `build.sh` Script

The `build.sh` script provides a convenient interface to build and export binaries.

### Export Mode (Builder Pattern with Local Export)

Export binaries for all architectures:

```bash
./build.sh -a all -e
```

Export to specific directory:

```bash
./build.sh -a all -e -o ./binaries
```

Export with version info:

```bash
./build.sh -a all -e -v 1.2.3
```

### Image Build Mode

Build Docker image for current platform:

```bash
./build.sh
```

Build for specific architecture:

```bash
./build.sh -a arm64
```

Build multi-platform image:

```bash
./build.sh -a all
```

Push to registry:

```bash
./build.sh -a all -r ghcr.io/bivex -p
```

## Examples

### Example 1: Quick Local Build

Build for your current platform only:

```bash
./build.sh
```

Output:
- Docker image: `kanboard-mcp:latest`

### Example 2: Export Binaries for Distribution

Generate Linux binaries for both architectures:

```bash
./build.sh -a all -e
```

Output:
```
dist/
├── linux-amd64/
│   ├── kanboard-mcp          # 7.6M binary
│   ├── etc/
│   │   └── ssl/
│   │       └── certs/
│   └── usr/
│       └── share/
│           └── zoneinfo/
└── linux-arm64/
    ├── kanboard-mcp          # 7.3M binary
    ├── etc/
    │   └── ssl/
    │       └── certs/
    └── usr/
        └── share/
            └── zoneinfo/
```

### Example 3: Build and Push to Registry

Build multi-platform image and push to GitHub Container Registry:

```bash
./build.sh -a all -r ghcr.io/bivex -p -t v1.2.3
```

Output:
- `ghcr.io/bivex/kanboard-mcp:v1.2.3` (multi-arch manifest)

### Example 4: Development Workflow

During development, iterate quickly with a single platform:

```bash
# Build for amd64 only (faster)
./build.sh -a amd64

# Export to test directory
./build.sh -a amd64 -e -o ./test-bin
```

### Example 5: CI/CD Pipeline

```yaml
# .github/workflows/build.yml
name: Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to GHCR
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        run: |
          VERSION=${GITHUB_REF#refs/tags/v}
          ./build.sh -a all -r ghcr.io/bivex -p -t $VERSION
```

## Artifacts

### Exported Files

When using the export mode (`-e`), the following files are generated:

```
dist/{platform}/
├── kanboard-mcp          # Main executable binary
├── etc/
│   └── ssl/
│       └── certs/
│           └── ca-certificates.crt  # SSL certificates
└── usr/
    └── share/
        └── zoneinfo/      # Timezone database
```

### Binary Properties

- **Static**: No external dependencies (besides libc)
- **Stripped**: Debug symbols removed (`-s -w` flags)
- **Optimized**: Size reduced (7.3-7.6 MB)
- **Version Info**: Embedded version and build time

### Using the Exported Binary

```bash
# Make executable
chmod +x dist/linux-amd64/kanboard-mcp

# Set environment variables
export KANBOARD_API_ENDPOINT='https://your-kanboard-url/jsonrpc.php'
export KANBOARD_API_KEY='your-api-key'

# Run
./dist/linux-amd64/kanboard-mcp
```

### Running in Docker Container

```bash
# Build image
docker build -t kanboard-mcp:latest .

# Run with environment variables
docker run --rm -it \
  -e KANBOARD_API_ENDPOINT='https://your-kanboard-url/jsonrpc.php' \
  -e KANBOARD_API_KEY='your-api-key' \
  kanboard-mcp:latest
```

## Best Practices

### 1. Use Export Mode for Distribution

When distributing binaries, prefer the export mode:

```bash
./build.sh -a all -e
```

**Benefits:**
- No Docker image overhead
- Direct binary access
- Smaller distribution size
- Easier to version and sign

### 2. Version Your Builds

Always specify version information:

```bash
./build.sh -v $(git describe --tags --always) -e
```

This embeds version info in the binary via ldflags.

### 3. Build Only What You Need

- For local development: `./build.sh -a amd64`
- For distribution: `./build.sh -a all -e`
- For deployment: `./build.sh -a all -r my-registry -p`

### 4. Leverage Docker Layer Caching

The build script is optimized for caching:

- Dependencies are cached separately from source code
- Platform-specific builds use shared cache layers
- `.dockerignore` excludes unnecessary files

### 5. Security Considerations

- **Builder Stage**: Contains build tools (not for production)
- **Runtime Stage**: Minimal, scratch-based (production-ready)
- **Export Stage**: Artifacts only, no entrypoint

Always validate the final image:

```bash
docker scan kanboard-mcp:latest
```

### 6. Cross-Platform Testing

Test binaries on target platforms:

```bash
# Export for both architectures
./build.sh -a all -e

# Test on amd64
docker run --rm -it --platform linux/amd64 \
  -v ./dist/linux-amd64:/app \
  -w /app \
  alpine ./kanboard-mcp --version

# Test on arm64 (if on ARM64 host)
docker run --rm -it --platform linux/arm64 \
  -v ./dist/linux-arm64:/app \
  -w /app \
  alpine ./kanboard-mcp --version
```

## Troubleshooting

### BuildKit Not Enabled

**Error:** BuildKit features not working

**Solution:** Enable BuildKit:
```bash
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain
```

### Cross-Platform Build Fails

**Error:** `exec format error` or similar

**Solution:** Ensure you're using buildx:
```bash
docker buildx version
docker buildx inspect --bootstrap
```

### Binary Too Large

**Solution:** Check build flags in Dockerfile:
```dockerfile
RUN go build \
    -ldflags="-s -w" \
    -a -installsuffix cgo \
    -o kanboard-mcp .
```

### Missing Dependencies in Exported Binary

**Solution:** Ensure you're copying certificates and timezone data:
```dockerfile
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
```

## Advanced Usage

### Custom Build Args

Modify Dockerfile build arguments:

```bash
docker build \
  --build-arg "VERSION=custom" \
  --build-arg "BUILD_TIME=$(date)" \
  --target export \
  --output type=local,dest=./out \
  .
```

### Parallel Builds

Build multiple architectures in parallel (default with `build.sh -a all`):

```bash
# The script already uses buildx which parallelizes builds
./build.sh -a all -e
```

### Multi-Platform Docker Image

Create a single image supporting both platforms:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag kanboard-mcp:latest \
  --push \
  .
```

## References

- [Docker Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Docker BuildKit](https://docs.docker.com/build/buildkit/)
- [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)
- [Go Cross-Compilation](https://golang.org/doc/install/source#environment)
- [Kanboard MCP Server](https://github.com/bivex/kanboard-mcp)

---

**Made with ❤️ for the Kanboard community**

