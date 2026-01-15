# 🚀 Kanboard MCP Server

> **Model Context Protocol (MCP) Server for Kanboard Integration**

A powerful Go-based MCP server that enables seamless integration between AI assistants (like Claude Desktop, Cursor) and Kanboard project management system. Manage your Kanboard projects, tasks, users, and workflows directly through natural language commands.

![Go](https://img.shields.io/badge/Go-1.21+-blue?style=for-the-badge&logo=go)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![MCP](https://img.shields.io/badge/MCP-Protocol-orange?style=for-the-badge)
![Docker](https://img.shields.io/badge/Docker-Supported-blue?style=for-the-badge&logo=docker)

> **Note:** This project was originally forked from [bivex/kanboard-mcp](https://github.com/bivex/kanboard-mcp) and is now maintained independently.


## 📋 Table of Contents

- [✨ Features](#-features)
- [🔍 Tool Search (Claude Code Integration)](#-tool-search-claude-code-integration)
- [🚀 Quick Start](#-quick-start)
- [🌐 Transport Modes](#-transport-modes)
- [🐳 Docker](#-docker)
- [⚙️ Configuration](#️-configuration)
- [🛠️ Available Tools](#️-available-tools)
- [📖 Usage Examples](#-usage-examples)
- [🔧 Development](#-development)
- [📄 License](#-license)

## ✨ Features

- 🔗 **Seamless Kanboard Integration** - Direct API communication with Kanboard
- 🤖 **Natural Language Processing** - Use plain English to manage your projects
- 📊 **Complete Project Management** - Handle projects, tasks, users, columns, and more
- 🔐 **Secure Authentication** - Support for both API key and username/password auth
- ⚡ **High Performance** - Built with Go for optimal performance
- 🎯 **MCP Standard** - Compatible with all MCP clients
- 🌐 **Multi-Transport Support** - stdio, SSE, and Streamable HTTP transports
- 🐳 **Docker Support** - Multi-architecture Docker images with Builder Pattern
- 📦 **Binary Distribution** - Export static binaries for Linux (AMD64/ARM64)
- 🚀 **Container Ready** - Designed for sidecar deployment in orchestrated environments
- 🔍 **Tool Search** - Built-in tool discovery with regex and BM25 search algorithms

## 🔍 Tool Search (Claude Code Integration)

This MCP server includes a built-in `tool_search` tool that enables dynamic tool discovery, compatible with [Claude's Tool Search feature](https://docs.anthropic.com/en/docs/build-with-claude/tool-use/tool-search-tool).

### Why Tool Search?

With 137+ available tools, loading all tools upfront can:
- Consume significant context tokens
- Overwhelm the model with too many options
- Slow down tool selection

Tool Search solves this by allowing Claude to discover relevant tools on-demand.

### The `tool_search` Tool

The `tool_search` tool is **always enabled** (not subject to configuration) and provides:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | Yes | Search pattern or keywords |
| `search_type` | string | No | `regex`, `bm25`, or `auto` (default) |
| `max_results` | number | No | Maximum results to return (default: 10) |

### Search Algorithms

| Algorithm | Best For | Example Query |
|-----------|----------|---------------|
| **regex** | Exact pattern matching | `create.*task`, `get_project` |
| **bm25** | Keyword relevance | `assign user to project`, `upload file` |
| **auto** | General use (tries regex, falls back to BM25) | Any query |

### Example Usage

**Search for task-related tools:**
```
Use tool_search with query "task" to find all task management tools
```

**Response:**
```json
{
  "query": "task",
  "search_type": "auto",
  "total_tools": 138,
  "result_count": 10,
  "results": [
    {
      "name": "create_task",
      "description": "Create a new task with title, description, assignee, due date, color, category, and column placement",
      "score": 1.5
    },
    {
      "name": "update_task",
      "description": "Update task properties: title, description, assignee, due date, color, category, priority, or column",
      "score": 1.5
    },
    ...
  ]
}
```

**Search with regex pattern:**
```
Use tool_search with query "get_.*_by_id" and search_type "regex"
```

**Search with BM25 for semantic matching:**
```
Use tool_search with query "upload file attachment" and search_type "bm25"
```

### Integration with Claude Code

When using Claude Code with this MCP server, you can leverage tool search for efficient workflows:

1. **Ask Claude to find relevant tools:**
   ```
   What tools are available for managing project files?
   ```
   Claude will use `tool_search` to discover `create_project_file`, `get_all_project_files`, etc.

2. **Discover tools by action:**
   ```
   How can I assign a user to a task?
   ```
   Claude will search for assignment-related tools and find `assign_task`.

3. **Explore available functionality:**
   ```
   What sprint management tools are available?
   ```
   Claude will find all sprint-related tools from the ScrumSprint plugin.

### Optimized Tool Descriptions

All 137+ tools have been optimized with rich descriptions to improve search accuracy:

- **Keywords**: Each description includes relevant action verbs and nouns
- **Parameters**: Descriptions mention key parameters (e.g., "base64 encoded content")
- **Context**: Descriptions explain the purpose (e.g., "for integration with external systems like GitHub/GitLab")
- **Return values**: Where applicable, descriptions note return types (e.g., "returns boolean")

**Example optimized descriptions:**
| Tool | Description |
|------|-------------|
| `create_task` | Create a new task with title, description, assignee, due date, color, category, and column placement |
| `search_tasks` | Search tasks using Kanboard query syntax (supports: assignee, status, due date, category, tag filters) |
| `get_task_by_reference` | Get task by external reference ID (for integration with external systems like GitHub/GitLab) |

## 🚀 Quick Start

### Prerequisites

- Go 1.21 or higher
- Kanboard instance with API access
- MCP-compatible client (Cursor, Claude Desktop, etc.)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd kanboard-mcp
   ```

2. **Build the executable:**

   **Option A: Using Docker (Recommended)**
   ```bash
   # Build Docker image
   ./build.sh

   # Or export Linux binaries directly
   ./build.sh -a all -e
   ```

   **Option B: Build scripts**
   - **On Windows:**
     ```cmd
     build-release.bat
     ```
   - **On Linux/macOS:**
     ```bash
     ./build-release.sh
     ```

   **Option C: Manual build**
   ```bash
   go build -ldflags="-s -w" -o kanboard-mcp .
   ```

## 🌐 Transport Modes

The Kanboard MCP Server supports multiple transport modes for different deployment scenarios:

| Transport | Mode | Use Case | Endpoint |
|-----------|------|----------|----------|
| **stdio** | `--stdio` (default) | Local development, CLI tools | stdin/stdout |
| **Streamable HTTP** | `--streamablehttp` | Container sidecars (recommended) | `http://host:port/mcp` |
| **SSE** | `--sse` | Legacy HTTP clients | `http://host:port/sse` |

### Transport Selection

**Via Command-Line Flags:**
```bash
# stdio mode (default)
./kanboard-mcp

# SSE mode
./kanboard-mcp --sse --port 8080

# Streamable HTTP mode (recommended for containers)
./kanboard-mcp --streamablehttp --port 8080
./kanboard-mcp --http --port 8080  # alias
```

**Via Environment Variables:**
```bash
export MCP_MODE=streamablehttp  # or: stdio, sse
export MCP_PORT=8080
./kanboard-mcp
```

### MCP Client Configuration

**Streamable HTTP (Recommended for containers):**
```json
{
  "mcpServers": {
    "kanboard": {
      "type": "streamableHttp",
      "url": "http://kanboard-mcp:8080/mcp"
    }
  }
}
```

**SSE:**
```json
{
  "mcpServers": {
    "kanboard": {
      "type": "sse",
      "url": "http://kanboard-mcp:8080/sse"
    }
  }
}
```

**stdio (Local):**
```json
{
  "mcpServers": {
    "kanboard": {
      "command": "/path/to/kanboard-mcp",
      "args": [],
      "env": {
        "KANBOARD_API_ENDPOINT": "https://your-kanboard/jsonrpc.php",
        "KANBOARD_API_KEY": "your-api-key"
      }
    }
  }
}
```

### Sidecar Architecture

For containerized deployments (Kubernetes, Docker Compose), use HTTP transports:

```
┌─────────────────┐   HTTP/SSE   ┌──────────────────────────┐
│  AI Agent       │ ←──────────→ │  kanboard-mcp sidecar    │
│  (Container A)  │              │                          │
│  MCP Client     │              │  :8080/mcp               │
└─────────────────┘              └──────────────────────────┘
                                           │
                                           ▼
                                 ┌──────────────────────────┐
                                 │  Kanboard Server         │
                                 │  JSON-RPC API            │
                                 └──────────────────────────┘
```

## 🐳 Docker

This project uses **Docker Builder Pattern** with Multi-Stage Build and Local Export to build the Kanboard MCP Server for Linux containers. This approach provides optimized, secure, and cross-platform builds.

### Quick Docker Start

**Using run.sh helper script (recommended):**
```bash
# stdio mode (interactive)
./run.sh

# SSE mode on port 8080
./run.sh --sse

# Streamable HTTP mode (recommended for containers)
./run.sh --http

# Run in background
./run.sh --http -d

# Build and run
./run.sh --build --http
```

**Run directly with Docker:**
```bash
# stdio mode
docker run --rm -it \
  -e KANBOARD_API_ENDPOINT='https://your-kanboard-url/jsonrpc.php' \
  -e KANBOARD_API_KEY='your-api-key' \
  kanboard-mcp:latest

# Streamable HTTP mode
docker run --rm -d \
  -p 8080:8080 \
  -e MCP_MODE=streamablehttp \
  -e KANBOARD_API_ENDPOINT='https://your-kanboard-url/jsonrpc.php' \
  -e KANBOARD_API_KEY='your-api-key' \
  kanboard-mcp:latest

# SSE mode
docker run --rm -d \
  -p 8080:8080 \
  -e MCP_MODE=sse \
  -e KANBOARD_API_ENDPOINT='https://your-kanboard-url/jsonrpc.php' \
  -e KANBOARD_API_KEY='your-api-key' \
  kanboard-mcp:latest
```

### Build with Docker

**Build for current platform:**
```bash
./build.sh
```

**Export binaries for distribution (Builder Pattern):**
```bash
# Export for both architectures (AMD64 and ARM64)
./build.sh -a all -e

# Output structure:
# dist/
# ├── linux-amd64/kanboard-mcp
# └── linux-arm64/kanboard-mcp
```

**Build Docker image for specific architecture:**
```bash
./build.sh -a arm64
./build.sh -a amd64
```

**Build multi-platform image:**
```bash
./build.sh -a all
```

### Available Build Options

```bash
./build.sh [OPTIONS]

Options:
    -a, --arch ARCH       Architecture: amd64, arm64, or all (default: current platform)
    -t, --tag TAG         Image tag (default: latest)
    -n, --name NAME       Image name (default: kanboard-mcp)
    -o, --output DIR      Output directory for local export (default: ./dist)
    -r, --registry REG    Registry to push to
    -p, --push            Push image to registry
    -e, --export-only     Export artifacts only, skip image creation
    -v, --version VER     Version string to embed in binary
    -h, --help            Show help message
```

### Examples

**Export binaries for both architectures:**
```bash
./build.sh -a all -e -v 1.2.3
```

**Build and push to Docker Hub:**
```bash
./build.sh -a all -r docker.io/yourusername -p -t v1.2.3
```

**Build for GitHub Container Registry:**
```bash
./build.sh -a all -r ghcr.io/yourusername -p -t v1.2.3
```

### Docker Image Details

- **Base Image**: `scratch` (minimal, secure)
- **Binary Size**: ~7.3 MB (AMD64), ~7.6 MB (ARM64)
- **Architectures**: `linux/amd64`, `linux/arm64`
- **Static Binary**: No external dependencies
- **Includes**: SSL certificates and timezone data

### Using Exported Binary

```bash
# Make executable
chmod +x dist/linux-amd64/kanboard-mcp

# Run with environment variables
export KANBOARD_API_ENDPOINT='https://your-kanboard-url/jsonrpc.php'
export KANBOARD_API_KEY='your-api-key'

./dist/linux-amd64/kanboard-mcp
```

### Docker Compose

The project includes a `docker-compose.yaml` with multiple transport configurations:

```bash
# Copy example environment file
cp .env.example .env
# Edit .env with your Kanboard credentials

# Start SSE server (port 8081)
docker-compose up mcp-sse

# Start Streamable HTTP server (port 8082)
docker-compose up mcp-http

# Start stdio mode (interactive)
docker-compose run --rm mcp-stdio

# Start with Kanboard for full testing
docker-compose --profile full up
```

**Available Services:**
| Service | Transport | Port | Endpoint |
|---------|-----------|------|----------|
| `mcp-sse` | SSE | 8081 | `http://localhost:8081/sse` |
| `mcp-http` | Streamable HTTP | 8082 | `http://localhost:8082/mcp` |
| `mcp-stdio` | stdio | - | Interactive |
| `kanboard` | - | 8080 | Web UI (profile: full) |

**Custom docker-compose.yaml example:**

```yaml
version: '3.8'
services:
  kanboard-mcp:
    build:
      context: .
      target: runtime
    container_name: kanboard-mcp
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - MCP_MODE=streamablehttp
      - MCP_PORT=8080
      - KANBOARD_API_ENDPOINT=https://your-kanboard-url/jsonrpc.php
      - KANBOARD_API_KEY=your-api-key
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Advanced Docker Usage

**Build with custom output directory:**
```bash
./build.sh -a all -e -o ./binaries
```

**Run with custom config:**
```bash
docker run --rm -it \
  -e KANBOARD_API_ENDPOINT='https://your-kanboard-url/jsonrpc.php' \
  -e KANBOARD_API_KEY='your-api-key' \
  -v $(pwd)/mcp-tools-config.yaml:/app/mcp-tools-config.yaml:ro \
  kanboard-mcp:latest
```

**Inspect binary version:**
```bash
# From exported binary
./dist/linux-amd64/kanboard-mcp

# Or from container
docker run --rm kanboard-mcp:latest
```

### What is Builder Pattern?

This project uses modern Docker Builder Pattern with:

1. **Multi-Stage Build**: Separate build and runtime environments for smaller, more secure images
2. **Local Export**: Extract binaries directly to host filesystem using `--output type=local`
3. **Cross-Platform**: Support for both AMD64 and ARM64 architectures
4. **Optimization**: Statically-linked binaries, stripped symbols, minimal size

**Benefits:**
- Minimal image size (~7.3 MB)
- No build tools in production images
- Direct binary distribution without Docker overhead
- Cross-platform builds from a single Dockerfile

For detailed documentation, see [DOCKER.md](DOCKER.md)

## ⚙️ Configuration

### 1. Tool Configuration (YAML)

The MCP server supports selective tool enabling through a YAML configuration file (`mcp-tools-config.yaml`). This allows you to control which tools are exposed to the MCP client, which is important for several reasons:

**Why Limit Tools?**
- **Model Limitations**: Some AI models cannot handle more than 80 tools in MCP. Limiting tools ensures compatibility.
- **Reduced Ambiguity**: Fewer tools mean clearer intent. For example, having both `delete_task` and `remove_project` can cause confusion when a user says "delete project" - the model might choose the wrong tool.
- **Better Performance**: Fewer tools mean faster tool selection and reduced token usage.
- **Security**: Only expose tools that are actually needed for your use case.

**Configuration File Location:**
The configuration file is automatically loaded from:
1. Path specified in `MCP_TOOLS_CONFIG` environment variable
2. `mcp-tools-config.yaml` in the same directory as the executable
3. Current working directory

**Configuration Structure:**
```yaml
# Domain: corerules
# Tools specified in .cursorrules file - these are always enabled
corerules:
  enabled: true
  tools:
    - create_task
    - update_task
    - delete_task
    - assign_task
    - move_task_position
    - set_task_tags
    - get_task
    - get_all_tasks
    # ... more tools

# All other domains are disabled by default
# Uncomment and enable domains as needed
tasks:
  enabled: false
  tools:
    - create_task
    - update_task
    # ... more task tools
```

**Available Domains:**
- `corerules` - Core tools required by cursor rules (always enabled if specified)
- `tasks` - Task management tools
- `projects` - Project management tools
- `comments` - Comment management
- `categories` - Category management
- `columns` - Column management
- `swimlanes` - Swimlane management
- `subtasks` - Subtask management
- `tags` - Tag management
- `users` - User management
- `groups` - Group management
- `links` - Task link management
- `actions` - Automated actions
- `board` - Board operations
- `sprints` - Sprint management
- `search` - Search operations
- `metadata` - Metadata operations
- `system` - System information
- `external_links` - External link providers
- `dashboard` - Dashboard and activity

**Example Configuration:**
```yaml
corerules:
  enabled: true
  tools:
    - create_task
    - update_task
    - delete_task
    - assign_task
    - get_task
    - get_all_tasks
    - get_project_users
    - assign_user_to_project
    - get_users
    - get_columns
```

**Note:** If the configuration file doesn't exist or a tool is not listed in any enabled domain, that tool will not be registered and will not be available to the MCP client.

### 2. Environment Variables

Set up your Kanboard credentials and RBAC permissions using environment variables:

#### Required Credentials:
```bash
export KANBOARD_API_ENDPOINT="https://your-kanboard-url/jsonrpc.php"
export KANBOARD_API_KEY="your-kanboard-api-key"
export KANBOARD_USERNAME="your-kanboard-username"
export KANBOARD_PASSWORD="your-kanboard-password"
```

#### RBAC Configuration (Optional):
Configure user roles for proper access control. If not set, the system will try to get roles from Kanboard API, falling back to `app-user` role.

```bash
# Application-level roles (comma-separated)
# If not set, roles are automatically retrieved from Kanboard API
export KANBOARD_USER_APP_ROLES="app-manager"

# Project-specific roles (format: "project_id:role,project_id:role")
# If not set, project roles are automatically retrieved from Kanboard API
export KANBOARD_USER_PROJECT_ROLES="1:project-manager,2:project-member"

# Debug mode - shows detailed permission checking logs
export KANBOARD_DEBUG="true"

# Skip RBAC checks for debugging (use with caution!)
export KANBOARD_SKIP_RBAC="false"
```

**Available Application Roles:**
- `app-admin` - Full system administrator access
- `app-manager` - Can create projects and manage users
- `app-user` - Basic user access (default)

**Available Project Roles:**
- `project-manager` - Full project management access
- `project-member` - Can create/modify tasks and comments
- `project-viewer` - Read-only access to project

**🔐 Authentication Methods:**

Kanboard supports different authentication methods via `KANBOARD_AUTH_METHOD`:

- **`global_token`** (default): Uses global API token with `jsonrpc:<token>` format
  ```bash
  export KANBOARD_API_KEY="5348e6b4846fe09fd1670e922bc13e086f0827d7a66e45815cd7c3a7f67b"
  export KANBOARD_AUTH_METHOD="global_token"  # or omit (default)
  ```

- **`user_token`**: Uses user-specific API token with `<username>:<token>` format
  ```bash
  export KANBOARD_USERNAME="admin"
  export KANBOARD_API_KEY="81820aeb3454985b0ac12166225f1f072f523175a752541c8670cf44a032d"
  export KANBOARD_AUTH_METHOD="user_token"
  ```

- **`bearer`**: Uses Bearer token authentication
  ```bash
  export KANBOARD_API_KEY="your-token-here"
  export KANBOARD_AUTH_METHOD="bearer"
  ```

**🔧 Troubleshooting RBAC Issues:**

If you're getting "access denied" errors:

1. **Check your user role in Kanboard:**
   - Go to Kanboard web interface
   - Check your user profile/role settings
   - Ensure you have appropriate permissions

2. **Enable debug logging:**
   ```bash
   export KANBOARD_DEBUG="true"
   ```
   This will show your current roles and permission checks in the console.

3. **Temporarily skip RBAC for testing:**
   ```bash
   export KANBOARD_SKIP_RBAC="true"
   ```
   ⚠️ **Warning:** Only use for debugging! Disables all permission checks.

4. **Manually set roles via environment:**
   ```bash
   export KANBOARD_USER_APP_ROLES="app-admin"
   export KANBOARD_USER_PROJECT_ROLES="27:project-manager"
   ```

### 3. MCP Client Configuration

Create the MCP configuration file for your client:

**Location:**
- **Windows:** `C:\Users\YOUR_USERNAME\AppData\Roaming\Cursor\.cursor\mcp_config.json`
- **Linux/macOS:** `~/.cursor/mcp_config.json`

**Configuration:**
```json
{
  "mcpServers": {
    "kanboard-mcp-server": {
      "command": "/path/to/your/kanboard-mcp",
      "args": [],
      "env": {
        "KANBOARD_API_ENDPOINT": "https://your-kanboard-url/jsonrpc.php",
        "KANBOARD_API_KEY": "your-kanboard-api-key",
        "KANBOARD_USERNAME": "your-kanboard-username",
        "KANBOARD_PASSWORD": "your-kanboard-password",
        "KANBOARD_USER_APP_ROLES": "app-manager",
        "KANBOARD_USER_PROJECT_ROLES": "1:project-manager"
      }
    }
  }
}
```

### 4. Restart Your Client

After saving the configuration, restart your MCP client (Cursor, Claude Desktop, etc.) for changes to take effect.

## 🛠️ Available Tools

### 📁 Project Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_projects` | 📋 List all projects | "Show me all Kanboard projects" |
| `create_project` | ➕ Create new projects | "Create a project called 'Website Redesign' with description 'Redesign the company website' and owner 1" |
| `get_project_by_id` | 🔍 Get project information by ID | "Get project details for ID 123" |
| `get_project_by_name` | 🔍 Get project information by name | "Get project details for name 'My Project'" |
| `get_project_by_identifier` | 🔍 Get project information by identifier | "Get project details for identifier 'WEB-APP'" |
| `get_project_by_email` | 🔍 Get project information by email | "Get project details for email 'project@example.com'" |
| `get_all_projects` | 📋 Get all available projects | "Show me all available projects" |
| `update_project` | ✏️ Update a project | "Update project 1 with new name 'New Website' and description 'Updated description'" |
| `remove_project` | 🗑️ Remove a project | "Remove project with ID 456" |
| `enable_project` | ✅ Enable a project | "Enable project 123" |
| `disable_project` | 🚫 Disable a project | "Disable project 123" |
| `enable_project_public_access` | 🌐 Enable public access for a given project | "Enable public access for project 123" |
| `disable_project_public_access` | 🔒 Disable public access for a given project | "Disable public access for project 123" |
| `get_project_activity` | 📢 Get activity stream for a project | "Show me activity for project 123" |
| `get_project_activities` | 📊 Get Activityfeed for Project(s) | "Get activities for projects 1, 2, and 3" |

### 📝 Task Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_tasks` | 📋 Get project tasks | "Get tasks for 'Website Redesign' project" |
| `create_task` | ➕ Create new tasks | "Create task 'Design homepage' in 'Website Redesign'" |
| `update_task` | ✏️ Modify existing tasks | "Update task 123 with description 'New requirements'" |
| `delete_task` | 🗑️ Remove tasks | "Delete task with ID 456" |
| `get_task` | 🔍 Get task by the unique id | "Get details for task 789" |
| `get_task_by_reference` | 🔍 Get task by the external reference | "Get task for project 1 with reference 'TICKET-1234'" |
| `get_all_tasks` | 📋 Get all available tasks | "Get all active tasks for project 1" |
| `get_overdue_tasks` | ⏰ Get all overdue tasks | "Show me all overdue tasks" |
| `get_overdue_tasks_by_project` | ⏰ Get all overdue tasks for a special project | "Show me overdue tasks for project 1" |
| `open_task` | ✅ Set a task to the status open | "Open task 123" |
| `close_task` | ❌ Set a task to the status close | "Close task 123" |
| `move_task_position` | ➡️ Move a task to another column, position or swimlane inside the same board | "Move task 123 to column 2, position 1, swimlane 1 in project 1" |
| `move_task_to_project` | ➡️ Move a task to another project | "Move task 123 to project 456" |
| `duplicate_task_to_project` | 📋 Duplicate a task to another project | "Duplicate task 123 to project 456" |
| `search_tasks` | 🔍 Find tasks by using the search engine | "Search tasks in project 2 for query 'assignee:nobody'" |
| `assign_task` | 👤 Assign tasks to users | "Assign the API task to John" |
| `set_task_due_date` | 📅 Set task deadlines | "Set due date for login task to 2024-01-15" |

**Note on `assign_task`:** This tool uses the Kanboard `updateTask` API method with the `owner_id` parameter. The `owner_id` field in Kanboard represents the responsible/assigned user (not the creator). If assignment fails, ensure the user is a member of the project and has appropriate permissions.

### 💬 Comment Management

| Tool | Description | Example |
|------|-------------|---------|
| `create_comment` | ➕ Create a new comment | "Create a comment 'Meeting notes' for task 123 by user 1, visible to app-managers" |
| `get_task_comments` | 📋 Get task comments | "Show all comments for task 123" |
| `get_comment` | 🔍 Get comment information | "Get details for comment 789" |
| `update_comment` | ✏️ Update a comment | "Update comment 456 content to 'Revised notes'" |
| `remove_comment` | 🗑️ Remove a comment | "Remove comment with ID 101" |

### 🏗️ Column Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_columns` | 📋 List project columns | "Show me all columns in project 123" |
| `get_column` | 🔍 Get a single column | "Get details for column 456" |
| `create_column` | ➕ Add new columns | "Create a 'Testing' column in project 123 with 5 task limit and description 'For UAT testing'" |
| `update_column` | ✏️ Modify column settings | "Change column 123 title to 'Review' and limit to 3 tasks, with description 'Needs final review'" |
| `change_column_position` | 🔄 Change column positions | "Move column 123 to position 3 in project 456" |
| `delete_column` | 🗑️ Remove columns | "Delete the unused 'Draft' column" |

### 🏷️ Category Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_categories` | 📋 List project categories | "Show me all task categories for project 123" |
| `get_category` | 🔍 Get category information | "Get details for category 456" |
| `create_category` | ➕ Add task categories | "Create a 'Bug Fixes' category in project 123 with color 'red'" |
| `update_category` | ✏️ Modify categories | "Rename category 123 to 'Critical Issues' and set color to 'blue'" |
| `delete_category` | 🗑️ Remove categories | "Delete the unused 'Archive' category" |

### 🏊 Swimlane Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_swimlanes` | 📋 List all swimlanes of a project (enabled or disabled) and sorted by position | "Show me all swimlanes for project 1" |
| `get_active_swimlanes` | 📋 Get the list of enabled swimlanes of a project (include default swimlane if enabled) | "Get active swimlanes for project 1" |
| `get_swimlane` | 🔍 Get a swimlane by ID | "Get swimlane details for ID 1" |
| `get_swimlane_by_id` | 🔍 Get a swimlane by ID | "Get swimlane details for ID 1" |
| `get_swimlane_by_name` | 🔍 Get a swimlane by name | "Get swimlane details for project 1 with name 'Swimlane 1'" |
| `change_swimlane_position` | 🔄 Move a swimlane's position (only for active swimlanes) | "Change swimlane 2 position to 3 in project 1" |
| `create_swimlane` | ➕ Add a new swimlane | "Create a swimlane 'Frontend Team' in project 1" |
| `update_swimlane` | ✏️ Update swimlane properties | "Update swimlane 1 for project 1 with new name 'Cross-Platform Team'" |
| `remove_swimlane` | 🗑️ Remove a swimlane | "Remove swimlane 1 from project 2" |
| `disable_swimlane` | 🚫 Disable a swimlane | "Disable swimlane 1 from project 2" |
| `enable_swimlane` | ✅ Enable a swimlane | "Enable swimlane 1 from project 2" |

### 📋 Board Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_board` | 📋 Get all necessary information to display a board | "Show me the board for project 123" |

### 🧑‍💻 Current User Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_me` | 👤 Get logged user session | "Get my user session information" |
| `get_my_dashboard` | 📊 Get the dashboard of the logged user | "Show me my dashboard" |
| `get_my_activity_stream` | 📢 Get the last 100 events for the logged user | "Show me my recent activity" |
| `create_my_private_project` | ➕ Create a private project for the logged user | "Create a private project named 'My Secret Project' with description 'For personal tasks'" |
| `get_my_projects_list` | 📋 Get projects of the connected user | "List all projects I'm involved in" |
| `get_my_overdue_tasks` | ⏰ Get my overdue tasks | "Show me all my tasks that are overdue" |
| `get_my_projects` | 📝 Get projects of connected user with full details | "Get detailed information about all my projects" |

### 🔗 External Task Link Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_external_task_link_types` | 📋 Get all registered external link providers | "Show me all external link types" |
| `get_ext_link_provider_deps` | ⛓️ Get available dependencies for a given provider | "Get dependencies for 'weblink' provider" |
| `create_external_task_link` | ➕ Create a new external link | "Create an external link for task 123 to 'http://example.com/doc.pdf' with dependency 'related' and type 'attachment'" |
| `update_external_task_link` | ✏️ Update external task link | "Update external link 456 for task 789 with new title 'Updated Document' and URL 'http://new.example.com/doc.pdf'" |
| `get_external_task_link_by_id` | 🔍 Get an external task link by ID | "Get external link 456 for task 789" |
| `get_all_external_task_links` | 📋 Get all external links attached to a task | "Show all external links for task 123" |
| `remove_external_task_link` | 🗑️ Remove an external link | "Remove external link 456 from task 789" |

### 🔗 Internal Task Link Management

| Tool | Description | Example |
|------|-------------|---------|
| `create_task_link` | ➕ Create a link between two tasks | "Create a link between task 123 and task 456 with link type 1" |
| `update_task_link` | ✏️ Update task link | "Update task link 789 between task 123 and task 456 with new link type 2" |
| `get_task_link_by_id` | 🔍 Get a task link by ID | "Get details for task link 101" |
| `get_all_task_links` | 📋 Get all links related to a task | "Show all links for task 123" |
| `remove_task_link` | 🗑️ Remove a link between two tasks | "Remove task link 101" |

### 🔗 Link Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_all_links` | 📋 Get the list of possible relations between tasks | "Show all possible task relations" |
| `get_opposite_link_id` | 🔍 Get the opposite link id of a task link | "Get the opposite link ID for link 2" |
| `get_link_by_label` | 🔍 Get a link by label | "Get details for link with label 'blocks'" |
| `get_link_by_id` | 🔍 Get a link by ID | "Get details for link with ID 4" |
| `create_link` | ➕ Create a new task relation | "Create a link 'foo' with opposite label 'bar'" |
| `update_link` | ✏️ Update a link | "Update link 14 with opposite link 12 and label 'boo'" |
| `remove_link` | 🗑️ Remove a link | "Remove link with ID 14" |

### 📂 Project File Management

| Tool | Description | Example |
|------|-------------|---------|
| `create_project_file` | ➕ Create and upload a new project attachment | "Create a file 'My Document.pdf' for project 1 with base64 content 'Zm9vYmFy'" or "Create a file '/path/to/document.pdf' for project 1" (file path will be read automatically) |
| `get_all_project_files` | 📋 Get all files attached to a project | "Show all files for project 123" |
| `get_project_file` | 🔍 Get file information | "Get details for file 456 in project 123" |
| `download_project_file` | 📥 Download project file contents (encoded in base64) | "Download file 456 from project 123" |
| `remove_project_file` | 🗑️ Remove a file associated to a project | "Remove file 456 from project 123" |
| `remove_all_project_files` | 🗑️ Remove all files associated to a project | "Remove all files from project 123" |

### 📝 Project Metadata Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_project_metadata` | 📋 Get Project metadata | "Get all metadata for project 123" |
| `get_project_metadata_by_name` | 🔍 Fetch single metadata value | "Get metadata 'my_key' for project 123" |
| `save_project_metadata` | 💾 Add or update metadata | "Save metadata 'key1:value1, key2:value2' for project 123" |
| `remove_project_metadata` | 🗑️ Remove a project metadata | "Remove metadata 'my_key' from project 123" |

### 🔐 Project Permission Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_project_users` | 📋 Get all members of a project | "Show all users in project 123" |
| `get_assignable_users` | 👥 Get users that can be assigned to a task for a project (all members except viewers) | "Get assignable users for project 123" |
| `add_project_user` | ➕ Grant access to a project for a user | "Add user 1 to project 123 with role 'project-member'" |
| `add_project_group` | ➕ Grant access to a project for a group | "Add group 456 to project 123 with role 'project-viewer'" |
| `remove_project_user` | 🗑️ Revoke user access to a project | "Remove user 1 from project 123" |
| `remove_project_group` | 🗑️ Revoke group access to a project | "Remove group 456 from project 123" |
| `change_project_user_role` | ✏️ Change role of a user for a project | "Change user 1's role in project 123 to 'project-manager'" |
| `change_project_group_role` | ✏️ Change role of a group for a project | "Change group 456's role in project 123 to 'project-manager'" |
| `get_project_user_role` | 🔍 Get the role of a user for a given project | "Get the role of user 1 in project 123" |

### 📝 Subtask Management

| Tool | Description | Example |
|------|-------------|---------|
| `create_subtask` | ➕ Create a new subtask | "Create a subtask 'Review designs' for task 123 with user 1 assigned" |
| `get_subtask` | 🔍 Get subtask information | "Get details for subtask 456" |
| `get_all_subtasks` | 📋 Get all available subtasks for a task | "Show all subtasks for task 123" |
| `update_subtask` | ✏️ Update a subtask | "Update subtask 456 for task 123 to status 2 (Done)" |
| `remove_subtask` | 🗑️ Remove a subtask | "Remove subtask with ID 456" |

### ⏰ Subtask Time Tracking

| Tool | Description | Example |
|------|-------------|---------|
| `has_subtask_timer` | ⏱️ Check if a timer is started for the given subtask and user | "Check if a timer is active for subtask 123 by user 4" |
| `set_subtask_start_time` | ▶️ Start subtask timer for a user | "Start timer for subtask 123 by user 4" |
| `set_subtask_end_time` | ⏹️ Stop subtask timer for a user | "Stop timer for subtask 123 by user 4" |
| `get_subtask_time_spent` | 📊 Get time spent on a subtask for a user | "Get time spent on subtask 123 by user 4" |

### 🏷️ Tag Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_all_tags` | 📋 Get all tags | "Show all available tags" |
| `get_tags_by_project` | 📋 Get all tags for a given project | "Show tags for project 123" |
| `create_tag` | ➕ Create a new tag | "Create tag 'backend' for project 123 with color 1" |
| `update_tag` | ✏️ Rename a tag | "Rename tag 456 to 'frontend' and set color to 2" |
| `remove_tag` | 🗑️ Remove a tag | "Remove tag with ID 456" |
| `set_task_tags` | 🏷️ Assign/Create/Update tags for a task | "Set tags 'urgent', 'bug' for task 123 in project 456" |
| `get_task_tags` | 🔍 Get assigned tags to a task | "Get tags assigned to task 123" |

### 📂 Task File Management

| Tool | Description | Example |
|------|-------------|---------|
| `create_task_file` | ➕ Create and upload a new task attachment | "Create a file 'meeting_notes.txt' for project 1 with task 2 and base64 content 'Zm9vYmFy'" or "Create a file '/path/to/notes.txt' for project 1 with task 2" (file path will be read automatically) |
| `get_all_task_files` | 📋 Get all files attached to task | "Show all files for task 123" |
| `get_task_file` | 🔍 Get file information | "Get details for file 456" |
| `download_task_file` | 📥 Download file contents (encoded in base64) | "Download file 456" |
| `remove_task_file` | 🗑️ Remove file | "Remove file with ID 456" |
| `remove_all_task_files` | 🗑️ Remove all files associated to a task | "Remove all files from task 123" |

### 📝 Task Metadata Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_task_metadata` | 📋 Get all metadata related to a task by task unique id | "Get all metadata for task 1" |
| `get_task_metadata_by_name` | 🔍 Get metadata related to a task by task unique id and metakey (name) | "Get metadata 'metaKey1' for task 1" |
| `save_task_metadata` | 💾 Save/update task metadata | "Save metadata 'metaName:metaValue' for task 1" |
| `remove_task_metadata` | 🗑️ Remove task metadata by name | "Remove metadata 'metaKey1' from task 1" |

### ⚙️ Application Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_version` | 📋 Get the application version | "What is the Kanboard version?" |
| `get_timezone` | 🌐 Get the timezone of the connected user | "What is my current timezone?" |
| `get_default_task_colors` | 🌈 Get all default task colors | "Show me all default task colors" |
| `get_default_task_color` | 🎨 Get default task color | "What is the default task color?" |
| `get_color_list` | 📋 Get the list of task colors | "List all available task colors" |
| `get_application_roles` | 👥 Get the application roles | "List all application roles" |
| `get_project_roles` | 👥 Get the project roles | "List all project roles" |

### 🤖 Automatic Actions Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_available_actions` | 📋 Get list of available automatic actions | "Show available automatic actions" |
| `get_available_action_events` | 📋 Get list of available events for actions | "Show available action events" |
| `get_compatible_action_events` | 🔍 Get list of events compatible with an action | "Get compatible events for action 'TaskClose'" |
| `get_actions` | 📋 Get list of actions for a project | "Get actions for project 123" |
| `create_action` | ➕ Create an action | "Create an action for project 1, event 'task.move.column', action '\Kanboard\Action\TaskClose', with params 'column_id:3'" |
| `remove_action` | 🗑️ Remove an action | "Remove action with ID 456" |

### 👥 Group Management

| Tool | Description | Example |
|------|-------------|---------|
| `create_group` | ➕ Create a new group | "Create a group named 'Development Team' with external ID 'dev_001'" |
| `update_group` | ✏️ Update a group | "Rename group 123 to 'QA Team' and change its external ID to 'qa_001'" |
| `remove_group` | 🗑️ Remove a group | "Remove group with ID 456" |
| `get_group` | 🔍 Get one group | "Get details for group 789" |
| `get_all_groups` | 📋 Get all groups | "Show me all user groups" |

### 👥 Group Member Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_member_groups` | 📋 Get all groups for a given user | "Show me all groups for user 1" |
| `get_group_members` | 👥 Get all members of a group | "List all members of group 123" |
| `add_group_member` | ➕ Add a user to a group | "Add user 456 to group 789" |
| `remove_group_member` | 🗑️ Remove a user from a group | "Remove user 456 from group 789" |
| `is_group_member` | ❓ Check if a user is member of a group | "Is user 456 a member of group 789?" |

### 👥 User Management

| Tool | Description | Example |
|------|-------------|---------|
| `get_users` | 📋 List all system users | "Show me all users" |
| `create_user` | ➕ Create a new user | "Create user 'john' with password '123456'" |
| `create_ldap_user` | ➕ Create a new user authenticated by LDAP | "Create LDAP user 'jane'" |
| `get_user` | 🔍 Get user information by ID | "Get user details for ID 123" |
| `get_user_by_name` | 🔍 Get user information by username | "Get user details for 'john'" |
| `update_user` | ✏️ Update a user | "Update user 123 with role 'app-manager'" |
| `remove_user` | 🗑️ Remove a user | "Remove user with ID 456" |
| `disable_user` | ❌ Disable a user | "Disable user 123" |
| `enable_user` | ✅ Enable a user | "Enable user 123" |
| `is_active_user` | 🔍 Check if a user is active | "Check if user 123 is active" |
| `assign_user_to_project` | 👤 Assign a user to a project with a specific role | "Assign user 1 to project 'Website' with role 'project-member'" |

### 🏃 ScrumSprint Plugin API

| Tool | Description | Example |
|------|-------------|---------|
| `create_sprint` | ➕ Create a new sprint | "Create a sprint named 'Sprint 1' in project 'My Project' starting '2024-01-01' and ending '2024-01-14' with goal 'Complete onboarding features'" |
| `get_sprint_by_id` | 🔍 Retrieve a sprint by its ID | "Get details for sprint with ID 123" |
| `update_sprint` | ✏️ Update an existing sprint | "Update sprint 123 in project 'My Project' to be completed" |
| `remove_sprint` | 🗑️ Remove a sprint by its ID | "Remove sprint with ID 123" |
| `get_all_sprints_by_project` | 📋 Retrieve all sprints for a given project | "Get all sprints for project 'My Project'" |

## 📖 Usage Examples

### Project Workflow

```bash
# Create a new project
"Create a new project called 'Mobile App Development'"

# Add tasks to the project
"Create task 'Design UI mockups' in project 'Mobile App Development'"
"Create task 'Set up development environment' in project 'Mobile App Development'"

# Get all tasks
"Get tasks for 'Mobile App Development' project"

# Move tasks between columns
"Move task 1 to 'In Progress' column"
"Move task 2 to 'Done' column"
```

### Team Management

```bash
# Create a new team member
"Create user 'alice.smith' with password 'secure123' and email 'alice@company.com'"

# Assign user to project
"Assign user 'alice.smith' to project 'Mobile App Development' as project-member"

# Assign tasks to team members
"Assign task 1 to user 'alice.smith'"
```

### Task Organization

```bash
# Create categories for better organization
"Create category 'Critical Bugs'"
"Create category 'Feature Requests'"

# Add comments to tasks
"Add comment 'This needs urgent attention' to task 5"

# Set deadlines
"Set due date for task 3 to 2024-01-20"
```

### File Attachments

You can attach files to projects and tasks in two ways:

**Option 1: Using file paths (recommended)**
```bash
# Attach a file to a project using a file path
# Relative paths are resolved from the current working directory
"Create a file 'document.pdf' for project 1"
"Create a file '/absolute/path/to/report.docx' for project 1"

# Attach a file to a task using a file path
"Create a file 'meeting_notes.txt' for project 1 with task 2"
"Create a file './documents/spec.pdf' for project 1 with task 2"
```

**Option 2: Using base64-encoded content**
```bash
# Attach a file with base64-encoded content
"Create a file 'My Document.pdf' for project 1 with base64 content 'Zm9vYmFy'"
"Create a file 'notes.txt' for project 1 with task 2 and base64 content 'SGVsbG8gV29ybGQ='"
```

**Note:** When using file paths:
- If the `blob` parameter is not provided, the `filename` parameter is treated as a file path
- Absolute paths are used as-is
- Relative paths are resolved relative to the current working directory
- The file is automatically read and encoded as base64 before uploading

## 🔧 Development

### Building from Source

```bash
# Clone the repository
git clone <repository-url>
cd kanboard-mcp

# Install dependencies
go mod download

# Build the application
go build -o kanboard-mcp .

# Run tests
go test ./...
```

### Project Structure

```
kanboard-mcp/
├── main.go              # Main application entry point
├── go.mod               # Go module dependencies
├── go.sum               # Dependency checksums
├── Dockerfile           # Multi-stage Docker build (Builder Pattern)
├── build.sh             # Docker build script with multi-arch support
├── build-darwin.sh      # macOS build script
├── build-release.bat     # Windows build script
├── build-release.sh      # Unix build script
├── mcp-tools-config.yaml # Tool configuration
├── README.md            # This file
├── DOCKER.md            # Docker documentation
└── LICENSE.md           # License information
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

---

<div align="center">

## Part of Heretic Project

This project is part of the **VibeCoder Heretic Project List** - a collection of AI-powered development tools and MCP servers.

[![Heretic](images/heretic-favicon-256x256.png)](https://github.com/giglabo/vibecoder-heretic-project-list)

[View the Heretic Project List](https://github.com/giglabo/vibecoder-heretic-project-list)

</div>
