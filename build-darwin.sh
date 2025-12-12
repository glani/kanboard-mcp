#!/bin/bash

# Build script for macOS (Darwin)
# Builds the kanboard-mcp application optimized for macOS

set -e  # Exit on any error

echo "🚀 Building kanboard-mcp for macOS (Darwin)..."

# Check and install Go if needed
check_and_install_go() {
    echo "🔍 Checking for Go installation..."

    if command -v go >/dev/null 2>&1; then
        echo "✅ Go is already installed"
        return 0
    fi

    echo "❌ Go is not installed"

    # Check if Homebrew is available
    if command -v brew >/dev/null 2>&1; then
        echo "🍺 Homebrew found, installing Go via brew..."
        echo "📦 Running: brew install go"

        if brew install go; then
            echo "✅ Go installed successfully via Homebrew"

            # Add Go to PATH for current session if needed
            if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]] && [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
                echo "🔧 Adding Go to PATH..."
                export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
            fi

            return 0
        else
            echo "❌ Failed to install Go via Homebrew"
            return 1
        fi
    else
        echo "❌ Homebrew is not installed"
        echo ""
        echo "📋 To install Go manually:"
        echo "1. Install Homebrew first:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo ""
        echo "2. Then install Go:"
        echo "   brew install go"
        echo ""
        echo "3. Or download Go directly from: https://golang.org/dl/"
        echo ""
        return 1
    fi
}

# Check and install Go
if ! check_and_install_go; then
    echo "❌ Cannot proceed without Go. Please install Go and try again."
    exit 1
fi

# Get system information
ARCH=$(uname -m)
OS=$(uname -s)
GO_VERSION=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//' || echo "unknown")

echo "📊 Build environment:"
echo "   OS: $OS"
echo "   Architecture: $ARCH"
echo "   Go version: $GO_VERSION"

# Clean any previous builds
echo "🧹 Cleaning previous builds..."
rm -f kanboard-mcp kanboard-mcp-*

# Set build flags for optimization
LDFLAGS="-s -w"
if [[ "$ARCH" == "arm64" ]]; then
    echo "🍎 Building for Apple Silicon (ARM64)..."
    GOOS=darwin GOARCH=arm64 go build -ldflags="$LDFLAGS" -o kanboard-mcp-arm64 .
elif [[ "$ARCH" == "x86_64" ]]; then
    echo "💻 Building for Intel (AMD64)..."
    GOOS=darwin GOARCH=amd64 go build -ldflags="$LDFLAGS" -o kanboard-mcp-amd64 .
else
    echo "⚠️  Unknown architecture $ARCH, building with default settings..."
    go build -ldflags="$LDFLAGS" -o kanboard-mcp .
fi

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"

    # Show binary information
    if command -v file >/dev/null 2>&1; then
        echo "📁 Binary information:"
        ls -la kanboard-mcp* 2>/dev/null || true
        file kanboard-mcp* 2>/dev/null || true
    fi

    echo ""
    echo "🎉 kanboard-mcp is ready for macOS!"
    echo "   To run: ./kanboard-mcp"
    echo ""
    echo "📚 Don't forget to set up your environment variables:"
    echo "   export KANBOARD_API_ENDPOINT='https://your-kanboard-url/jsonrpc.php'"
    echo "   export KANBOARD_API_KEY='your-api-key'"
    echo "   # ... see README.md for complete configuration"
else
    echo "❌ Build failed!"
    exit 1
fi
