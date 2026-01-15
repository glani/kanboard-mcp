#!/bin/sh
# =============================================================================
# Kanboard MCP Server Entrypoint
# Handles transport mode selection and server startup
# =============================================================================

set -e

# Default values
MODE="${MCP_MODE:-stdio}"
PORT="${MCP_PORT:-8080}"

# Print startup banner
echo "KanboardMCP Server" >&2
echo "==================" >&2
echo "Transport mode: ${MODE}" >&2

# Start the server based on transport mode
case "${MODE}" in
    stdio)
        echo "Starting with stdio transport..." >&2
        exec /kanboard-mcp
        ;;
    sse)
        echo "Starting with SSE transport on port ${PORT}..." >&2
        exec /kanboard-mcp --sse --port "${PORT}"
        ;;
    streamablehttp|http)
        echo "Starting with Streamable HTTP transport on port ${PORT}..." >&2
        exec /kanboard-mcp --streamablehttp --port "${PORT}"
        ;;
    *)
        echo "Unknown mode: ${MODE}. Using stdio." >&2
        exec /kanboard-mcp
        ;;
esac
