# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Kanboard MCP Server is a Go-based Model Context Protocol (MCP) server that enables AI assistants (Claude Desktop, Cursor) to interact with Kanboard project management via natural language. It implements the Kanboard JSON-RPC API as MCP tools.

## Build Commands

```bash
# Build locally (macOS)
go build -ldflags="-s -w" -o kanboard-mcp .

# Build with Docker (recommended for Linux binaries)
./build.sh                    # Build for current platform
./build.sh -a all -e          # Export binaries for AMD64 and ARM64

# Run tests
go test ./...

# Install dependencies
go mod download
```

## Architecture

### Single-File Design

The entire application lives in `main.go` (~6000 lines). This is intentional for simplicity and single-binary distribution.

### Key Components

1. **MCP Server** (`main()` at line 909): Initializes the MCP server using `github.com/mark3labs/mcp-go`, registers tools based on configuration, and starts the server with the selected transport mode.

2. **Transport Layer** (lines 3127-3212): Supports multiple transport modes:
   - `stdio`: Default, for local CLI usage
   - `sse`: Server-Sent Events over HTTP
   - `streamablehttp`: Streamable HTTP (recommended for containers)

3. **Kanboard Client** (`kanboardClient` struct at line 3214): HTTP client for Kanboard JSON-RPC API. Handles authentication (API key, user token, or bearer) and request/response marshaling.

4. **RBAC Manager** (`RBACManager` at line 483): Role-based access control system with embedded JSON configuration. Validates permissions before API calls based on application roles (app-admin, app-manager, app-user) and project roles (project-manager, project-member, project-viewer).

5. **Tool Configuration** (`MCPToolsConfig` at line 762): YAML-based configuration (`mcp-tools-config.yaml`) that controls which MCP tools are exposed. Tools are grouped by domain (corerules, tasks, projects, etc.).

### Tool Registration Pattern

Each Kanboard API method is exposed as an MCP tool:
1. Tool defined with `mcp.NewTool()` including parameters
2. Handler method on `kanboardClient` (e.g., `createTaskHandler`)
3. Registration via `registerToolIfEnabled()` which checks the YAML config

### Authentication Flow

Set via environment variables:
- `KANBOARD_API_ENDPOINT`: JSON-RPC endpoint URL
- `KANBOARD_API_KEY`: API token
- `KANBOARD_AUTH_METHOD`: `global_token` (default), `user_token`, or `bearer`
- `KANBOARD_USERNAME`/`KANBOARD_PASSWORD`: For user token auth

### Adding New Tools

1. Add handler method to `kanboardClient` following existing patterns
2. Define the tool with `mcp.NewTool()` in `main()`
3. Call `registerToolIfEnabled()` with appropriate name
4. Add tool name to relevant domain in `mcp-tools-config.yaml`

## Configuration Files

- `mcp-tools-config.yaml`: Controls which tools are exposed (important for model tool limits)
- `Dockerfile`: Multi-stage build for minimal scratch-based images
- `build.sh`: Docker build script with multi-arch support

## Environment Variables for Development

```bash
# Transport configuration
export MCP_MODE="stdio"                # Transport: stdio, sse, streamablehttp
export MCP_PORT="8080"                 # Port for HTTP/SSE transports

# Debug and testing
export KANBOARD_DEBUG="true"           # Enable debug logging
export KANBOARD_SKIP_RBAC="false"      # Bypass RBAC for testing
export MCP_TOOLS_CONFIG="path/to/config.yaml"  # Custom config location
```

## Running with Different Transports

```bash
# stdio (default) - for local CLI usage
./kanboard-mcp

# SSE - for HTTP clients
./kanboard-mcp --sse --port 8080

# Streamable HTTP - recommended for container sidecars
./kanboard-mcp --streamablehttp --port 8080

# Using Docker
./run.sh --http -d          # Streamable HTTP in background
./run.sh --sse              # SSE mode
docker-compose up mcp-http  # Using docker-compose
```
