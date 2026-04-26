# MCP Setup

## Dart/Flutter MCP

Built into the project — no setup needed. Requires Dart SDK 3.9+.

## Flame MCP

Community MCP server providing offline Flame documentation and tutorials.
Repo: https://github.com/salihgueler/flame_mcp_server

### Setup

1. Clone and build:

```bash
git clone https://github.com/salihgueler/flame_mcp_server.git /path/to/projects/flutter/flame_mcp_server
cd /path/to/projects/flutter/flame_mcp_server
dart pub get
mkdir -p build
dart compile exe bin/flame_mcp_live.dart -o build/flame_mcp_live.exe
```

2. Sync Flame documentation locally:

```bash
dart run bin/flame_doc_syncer.dart
```

> To avoid GitHub rate limits (60 req/hr), set a personal access token first:
> `export GITHUB_TOKEN=your_token_here`

3. Register with Claude Code:

```bash
claude mcp add --scope user flame "/absolute/path/to/flame_mcp_server/build/flame_mcp_live.exe"
```

4. Verify:

```bash
claude mcp list
```

The `flame` server should show `✓ Connected`.
