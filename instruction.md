Write two CLAUDE.md files from current project structure + session context:

1. ~/.claude/CLAUDE.md — global, language-agnostic, all projects:
- Workflow: increment small, one feature at a time, ask before deleting
- Logging: never use print/debugPrint, use project custom logger
- Run analyzer/linter before finishing task
- Update project CLAUDE.md checklist after each completed feature
- Never rewrite working code unless asked
- Task ambiguous → ask one clarifying question before starting

2. Project CLAUDE.md at repo root — Flutter/Flame template:
- Current stack + versions
- Project folder structure
- Device ID + run commands
- Logger usage (appLog.info/warn/error, cid+ctx required for warn+)
- MCP servers available (dart, flame)
- Current build state checklist
- Conventions (one component per file, Flutter widgets for UI, Flame for game objects)

Read existing files, MCP_SETUP.md, pubspec.yaml, .claude/settings.json before writing. No invention.