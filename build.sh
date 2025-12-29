#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build Kanboard MCP Server Docker image using Builder Pattern with Multi-Stage Build and Local Export.

Options:
    -a, --arch ARCH       Architecture: amd64, arm64, or all (default: current platform)
    -t, --tag TAG         Image tag (default: latest)
    -n, --name NAME       Image name (default: kanboard-mcp)
    -o, --output DIR      Output directory for local export (default: ./dist)
    -r, --registry REG    Registry to push to (enables push mode)
    -p, --push            Push image to registry
    -e, --export-only     Export artifacts only, skip image creation
    -v, --version VER     Version string to embed in binary (default: dev)
    -h, --help            Show this help message

Builder Pattern:
    This script implements the modern Docker Builder Pattern with:
    1. Multi-Stage Build: Separate build and runtime stages
    2. Local Export: Extract binaries directly to host filesystem using --output flag
    3. Cross-Platform: Support for amd64 and arm64 architectures

Examples:
    # Build for current platform only
    $(basename "$0")

    # Build for specific architecture
    $(basename "$0") -a arm64

    # Build for all architectures and push to registry
    $(basename "$0") -a all -r ghcr.io/bivex -p

    # Export binaries locally for all architectures (Builder Pattern)
    $(basename "$0") -a all -e

    # Export to specific directory
    $(basename "$0") -a all -e -o ./binaries

    # Build image with version tag
    $(basename "$0") -t v1.2.3 -v 1.2.3

Exported Files:
    When using --export-only, binaries are extracted as:
    ./dist/linux-amd64/kanboard-mcp
    ./dist/linux-arm64/kanboard-mcp

EOF
    exit 0
}

# Default values
IMAGE_NAME="kanboard-mcp"
IMAGE_TAG="latest"
REGISTRY=""
ARCH=""
DO_PUSH="false"
DO_EXPORT_ONLY="false"
OUTPUT_DIR="./dist"
VERSION="dev"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--arch)
            ARCH="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -p|--push)
            DO_PUSH="true"
            shift
            ;;
        -e|--export-only)
            DO_EXPORT_ONLY="true"
            shift
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Error: Unknown option: $1"
            usage
            ;;
    esac
done

cd "$SCRIPT_DIR"

# Determine platforms based on architecture argument
case "$ARCH" in
    amd64|x86_64)
        PLATFORMS="linux/amd64"
        ;;
    arm64|aarch64)
        PLATFORMS="linux/arm64"
        ;;
    all|both)
        PLATFORMS="linux/amd64,linux/arm64"
        ;;
    "")
        # Detect current platform if not specified
        CURRENT_ARCH=$(uname -m)
        if [[ "$CURRENT_ARCH" == "arm64" ]] || [[ "$CURRENT_ARCH" == "aarch64" ]]; then
            PLATFORMS="linux/arm64"
        else
            PLATFORMS="linux/amd64"
        fi
        ;;
    *)
        echo "Error: Invalid architecture '$ARCH'. Use: amd64, arm64, or all"
        exit 1
        ;;
esac

# Build full image name
if [ -n "$REGISTRY" ]; then
    FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
else
    FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
fi

# Set build time for version info
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Enable BuildKit if not already enabled
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain

echo "=========================================="
echo "🐳 Kanboard MCP Builder Pattern Build"
echo "=========================================="
echo "Image: $FULL_IMAGE_NAME"
echo "Platform(s): $PLATFORMS"
echo "Version: $VERSION"
echo "Build Time: $BUILD_TIME"
echo "=========================================="

if [ "$DO_EXPORT_ONLY" = "true" ]; then
    # =============================================================================
    # EXPORT MODE: Builder Pattern with Local Export
    # This is the modern approach to extract artifacts without creating images
    # =============================================================================
    echo ""
    echo "📦 Export Mode: Extracting binaries using Builder Pattern"
    echo "Output Directory: $OUTPUT_DIR"
    echo ""

    # Split platforms into array
    IFS=',' read -ra PLATFORM_ARRAY <<< "$PLATFORMS"

    # Build and export for each platform
    for PLATFORM in "${PLATFORM_ARRAY[@]}"; do
        # Parse platform
        PLATFORM_OS=$(echo "$PLATFORM" | cut -d'/' -f1)
        PLATFORM_ARCH=$(echo "$PLATFORM" | cut -d'/' -f2)

        # Create architecture-specific output directory
        ARCH_OUTPUT_DIR="${OUTPUT_DIR}/${PLATFORM_OS}-${PLATFORM_ARCH}"
        mkdir -p "$ARCH_OUTPUT_DIR"

        echo "------------------------------------------------"
        echo "Building for ${PLATFORM_OS}/${PLATFORM_ARCH}..."
        echo "------------------------------------------------"

        # Build with local export using the export stage
        docker buildx build \
            --platform "$PLATFORM" \
            --target export \
            --output "type=local,dest=${ARCH_OUTPUT_DIR}" \
            --build-arg "TARGETOS=${PLATFORM_OS}" \
            --build-arg "TARGETARCH=${PLATFORM_ARCH}" \
            --build-arg "VERSION=${VERSION}" \
            --build-arg "BUILD_TIME=${BUILD_TIME}" \
            .

        echo "✅ Exported to: ${ARCH_OUTPUT_DIR}/"

        # Show the exported files
        if [ -d "$ARCH_OUTPUT_DIR" ]; then
            echo "📁 Exported files:"
            ls -lh "$ARCH_OUTPUT_DIR/"
        fi
    done

    echo ""
    echo "=========================================="
    echo "✨ Export Complete!"
    echo "=========================================="
    echo "Location: $OUTPUT_DIR"
    echo ""
    echo "To use the binary:"
    echo "  # For AMD64"
    echo "  ./dist/linux-amd64/kanboard-mcp"
    echo ""
    echo "  # For ARM64"
    echo "  ./dist/linux-arm64/kanboard-mcp"
    echo "=========================================="

else
    # =============================================================================
    # IMAGE MODE: Build Docker images
    # =============================================================================
    if [[ "$PLATFORMS" == *","* ]]; then
        # Multi-platform build
        echo ""
        echo "🔧 Mode: Multi-platform build with buildx"
        echo ""

        BUILD_ARGS=(
            --platform "$PLATFORMS"
            --build-arg "VERSION=${VERSION}"
            --build-arg "BUILD_TIME=${BUILD_TIME}"
            --tag "$FULL_IMAGE_NAME"
        )

        if [ "$DO_PUSH" = "true" ]; then
            echo "📤 Pushing to registry..."
            docker buildx build "${BUILD_ARGS[@]}" --push .
        else
            echo "💾 Building locally (multi-platform)..."
            docker buildx build "${BUILD_ARGS[@]}" --load .
        fi
    else
        # Single platform build
        echo ""
        echo "🔧 Mode: Single platform build"
        echo ""

        if [ "$DO_PUSH" = "true" ] && [ -n "$REGISTRY" ]; then
            # Build and push in two steps for single platform
            echo "🏗️  Building image..."
            docker build \
                --tag "$FULL_IMAGE_NAME" \
                --build-arg "TARGETOS=linux" \
                --build-arg "TARGETARCH=$(echo $PLATFORMS | cut -d'/' -f2)" \
                --build-arg "VERSION=${VERSION}" \
                --build-arg "BUILD_TIME=${BUILD_TIME}" \
                .

            echo "📤 Pushing to registry..."
            docker push "$FULL_IMAGE_NAME"
        else
            echo "🏗️  Building image..."
            docker build \
                --tag "$FULL_IMAGE_NAME" \
                --build-arg "TARGETOS=linux" \
                --build-arg "TARGETARCH=$(echo $PLATFORMS | cut -d'/' -f2)" \
                --build-arg "VERSION=${VERSION}" \
                --build-arg "BUILD_TIME=${BUILD_TIME}" \
                .
        fi
    fi

    echo ""
    echo "=========================================="
    echo "✨ Build Complete!"
    echo "=========================================="
    echo "Image: $FULL_IMAGE_NAME"
    echo "=========================================="

    if [ "$DO_PUSH" = "false" ]; then
        echo ""
        echo "To run the container:"
        echo "  docker run --rm -it \\"
        echo "    -e KANBOARD_API_ENDPOINT='https://your-kanboard-url/jsonrpc.php' \\"
        echo "    -e KANBOARD_API_KEY='your-api-key' \\"
        echo "    $FULL_IMAGE_NAME"
        echo ""
    fi
fi

echo "✅ All done!"

