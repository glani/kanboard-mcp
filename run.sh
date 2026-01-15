#!/bin/bash
# =============================================================================
# Kanboard MCP Server Docker Runner
# Simplifies running the MCP server in different transport modes
# =============================================================================

set -e

# Default values
IMAGE_NAME="${IMAGE_NAME:-kanboard-mcp}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_NAME="kanboard-mcp"
PORT="${MCP_PORT:-8080}"
DETACH=""
MODE="stdio"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Run Kanboard MCP Server in Docker with different transport modes."
    echo ""
    echo "Options:"
    echo "  --stdio             Use stdio transport (default, interactive)"
    echo "  --sse               Use SSE transport (HTTP server)"
    echo "  --streamablehttp    Use Streamable HTTP transport (recommended for containers)"
    echo "  --http              Alias for --streamablehttp"
    echo "  -d, --detach        Run container in background"
    echo "  -p, --port PORT     Port for HTTP/SSE transport (default: 8080)"
    echo "  --build             Build the image before running"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  KANBOARD_API_ENDPOINT  Kanboard JSON-RPC endpoint"
    echo "  KANBOARD_API_KEY       Kanboard API key"
    echo "  KANBOARD_USERNAME      Kanboard username (for user_token auth)"
    echo "  KANBOARD_PASSWORD      Kanboard password (for user_token auth)"
    echo "  KANBOARD_AUTH_METHOD   Authentication method (global_token, user_token, bearer)"
    echo "  KANBOARD_DEBUG         Enable debug logging (true/false)"
    echo ""
    echo "Examples:"
    echo "  $0                      # Run in stdio mode (interactive)"
    echo "  $0 --sse                # Run SSE server on port 8080"
    echo "  $0 --http -d            # Run HTTP server in background"
    echo "  $0 --sse -p 9000        # Run SSE server on port 9000"
    echo "  $0 --build --http       # Build and run HTTP server"
}

BUILD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --stdio)
            MODE="stdio"
            shift
            ;;
        --sse)
            MODE="sse"
            shift
            ;;
        --streamablehttp|--http)
            MODE="streamablehttp"
            shift
            ;;
        -d|--detach)
            DETACH="-d"
            shift
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        --build)
            BUILD=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Build if requested
if [ "$BUILD" = true ]; then
    echo -e "${YELLOW}Building Docker image...${NC}"
    docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" --target runtime .
fi

# Check if image exists
if ! docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" >/dev/null 2>&1; then
    echo -e "${YELLOW}Image not found. Building...${NC}"
    docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" --target runtime .
fi

# Stop existing container if running
if docker ps -q -f name="${CONTAINER_NAME}" | grep -q .; then
    echo -e "${YELLOW}Stopping existing container...${NC}"
    docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
fi

# Remove existing container
docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true

# Build docker run command
DOCKER_CMD="docker run --rm"
DOCKER_CMD+=" --name ${CONTAINER_NAME}"

# Add environment variables
[ -n "$KANBOARD_API_ENDPOINT" ] && DOCKER_CMD+=" -e KANBOARD_API_ENDPOINT=${KANBOARD_API_ENDPOINT}"
[ -n "$KANBOARD_API_KEY" ] && DOCKER_CMD+=" -e KANBOARD_API_KEY=${KANBOARD_API_KEY}"
[ -n "$KANBOARD_USERNAME" ] && DOCKER_CMD+=" -e KANBOARD_USERNAME=${KANBOARD_USERNAME}"
[ -n "$KANBOARD_PASSWORD" ] && DOCKER_CMD+=" -e KANBOARD_PASSWORD=${KANBOARD_PASSWORD}"
[ -n "$KANBOARD_AUTH_METHOD" ] && DOCKER_CMD+=" -e KANBOARD_AUTH_METHOD=${KANBOARD_AUTH_METHOD}"
[ -n "$KANBOARD_DEBUG" ] && DOCKER_CMD+=" -e KANBOARD_DEBUG=${KANBOARD_DEBUG}"

# Mode-specific options
case $MODE in
    stdio)
        DOCKER_CMD+=" -it"
        DOCKER_CMD+=" -e MCP_MODE=stdio"
        echo -e "${GREEN}Starting Kanboard MCP in stdio mode...${NC}"
        ;;
    sse)
        DOCKER_CMD+=" -p ${PORT}:8080"
        DOCKER_CMD+=" -e MCP_MODE=sse"
        DOCKER_CMD+=" -e MCP_PORT=8080"
        [ -n "$DETACH" ] && DOCKER_CMD+=" ${DETACH}"
        echo -e "${GREEN}Starting Kanboard MCP SSE server on port ${PORT}...${NC}"
        ;;
    streamablehttp)
        DOCKER_CMD+=" -p ${PORT}:8080"
        DOCKER_CMD+=" -e MCP_MODE=streamablehttp"
        DOCKER_CMD+=" -e MCP_PORT=8080"
        [ -n "$DETACH" ] && DOCKER_CMD+=" ${DETACH}"
        echo -e "${GREEN}Starting Kanboard MCP HTTP server on port ${PORT}...${NC}"
        ;;
esac

DOCKER_CMD+=" ${IMAGE_NAME}:${IMAGE_TAG}"

# Run the container
eval $DOCKER_CMD

# Show connection info for HTTP modes
if [ "$MODE" != "stdio" ] && [ -n "$DETACH" ]; then
    echo ""
    echo -e "${GREEN}Container started in background.${NC}"
    echo ""
    if [ "$MODE" = "sse" ]; then
        echo "SSE endpoint: http://localhost:${PORT}/sse"
        echo "Message endpoint: http://localhost:${PORT}/message"
    else
        echo "MCP endpoint: http://localhost:${PORT}/mcp"
    fi
    echo "Health check: http://localhost:${PORT}/health"
    echo ""
    echo "To view logs: docker logs -f ${CONTAINER_NAME}"
    echo "To stop: docker stop ${CONTAINER_NAME}"
fi
