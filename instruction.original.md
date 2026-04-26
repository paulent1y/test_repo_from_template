Write two CLAUDE.md files based on the current project structure and session context:

1. ~/.claude/CLAUDE.md — global, language-agnostic, applies to all projects:
- Workflow behavior (increment small, one feature at a time, ask before deleting)
- Logging rules (never use print/debugPrint, always use project's custom logger)
- Always run analyzer/linter before finishing a task
- Update project CLAUDE.md current state checklist after each completed feature
- Never rewrite working code unless explicitly asked
- If task is ambiguous, ask one clarifying question before starting

2. Project CLAUDE.md at repo root — Flutter/Flame template specific:
- Current stack and versions
- Project folder structure
- Device ID and run commands
- Logger usage (appLog.info/warn/error with required cid+ctx for warn+)
- MCP servers available (dart, flame)
- Current build state checklist
- Conventions (one component per file, Flutter widgets for UI, Flame for game objects)

Read the existing files, MCP_SETUP.md, pubspec.yaml, and .claude/settings.json before writing. 
Do not invent anything not present in the project.