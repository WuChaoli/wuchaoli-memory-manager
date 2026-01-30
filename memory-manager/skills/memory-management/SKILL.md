---
name: Memory Management
description: This skill should be used when the user asks to "manage memory", "save session", "load memory", "search history", "organize memories", or mentions memory persistence, session recovery, or context management. Provides comprehensive guidance for managing Claude Code session memories and long-term knowledge.
version: 0.1.0
---

# Memory Management

## Overview

Memory management enables persistent session context across Claude Code sessions through a three-tier storage architecture: active task memories (JSON), archived task memories (JSON), and long-term knowledge (SQLite). This skill provides guidance for effectively managing memories throughout their lifecycle.

## Core Concepts

### Three-Tier Storage Architecture

**Active Tasks** (`.claude/memory/active-tasks/`)
- Current working context
- Session-by-session records
- Task metadata and artifacts
- Lifecycle: Creation → Active development → Completion

**Archived Tasks** (`.claude/memory/archived-tasks/`)
- Completed task records
- Organized by month (YYYY-MM)
- Full session history preserved
- Lifecycle: Archive → Long-term storage extraction

**Long-Term Knowledge** (`.claude/memory/long-term/knowledge.db`)
- SQLite database with FTS5 search
- Extracted insights and decisions
- Cross-task knowledge synthesis
- Lifecycle: Continuous accumulation

### Memory Lifecycle

```
New Task → Active Development → Task Completion → Archive → Long-Term Knowledge
   ↓              ↓                    ↓              ↓            ↓
Create task   Auto-save         Detect completion  Extract    Store in
metadata      sessions          Prompt archive     insights   SQLite
```

## Task-Driven Organization

### Creating Tasks

Tasks are the primary organizational unit. Create a new task when starting significant work:

```bash
# Task directory structure
.claude/memory/active-tasks/task-{id}-{name}/
├── context.json       # Task metadata
├── sessions/          # Session records
│   ├── 2026-01-29-001.json
│   └── 2026-01-29-002.json
└── artifacts/         # Related files
```

**Task Metadata** (`context.json`):
```json
{
  "id": "001",
  "name": "api-authentication",
  "description": "Implement JWT authentication for API",
  "created_at": "2026-01-29T10:00:00Z",
  "status": "active",
  "tags": ["api", "auth", "backend"]
}
```

### Session Management

Sessions represent individual Claude Code conversations within a task. Each session automatically saves:

- User messages and assistant responses
- Tool calls and results
- Important decisions and code changes
- Timestamps and context position

**Session Record Format**:
```json
{
  "session_id": "2026-01-29-001",
  "task_id": "001",
  "started_at": "2026-01-29T10:00:00Z",
  "ended_at": "2026-01-29T11:30:00Z",
  "messages": [
    {
      "role": "user",
      "content": "...",
      "timestamp": "..."
    }
  ],
  "summary": "Implemented JWT token generation and validation"
}
```

## Memory Operations

### Saving Memories

**Automatic Saving** (PostToolUse Hook):
- Triggers after file modifications (Write, Edit)
- Triggers after Git operations (commit, push)
- Triggers after test execution
- Triggers after important Bash commands

**Manual Saving** (`/memory:save`):
- Save current session immediately
- Useful before risky operations
- Creates checkpoint for recovery

### Loading Memories

**Automatic Loading** (SessionStart Hook):
- Loads most recent session on startup
- Displays task context and progress
- Merges with CLAUDE.md rules

**Manual Loading** (`/memory:load`):
- Load specific task or session
- Replace current context (warning shown)
- Useful for context switching

**Loading Strategy**:
1. CLAUDE.md (auto-loaded by Claude Code)
2. Recent session from SQLite (auto-loaded)
3. Serena knowledge (loaded if needed)

### Searching Memories

Use `/memory:search` with multiple search modes:

**Full-Text Search**:
```
/memory:search "JWT authentication"
```

**Task-Specific Search**:
```
/memory:search --task api-auth "token validation"
```

**Time-Range Search**:
```
/memory:search --from 2026-01-20 --to 2026-01-29 "bug fix"
```

**Role-Based Search**:
```
/memory:search --role user "how to implement"
```

Search uses SQLite FTS5 for fast full-text search across all memories.

### Organizing Memories

**Automatic Organization** (memory-organizer agent):
- Runs at session end (Stop Hook)
- Categorizes memories by topic
- Removes duplicates
- Extracts key insights

**Manual Organization** (`/memory:organize`):
- Trigger organization immediately
- Useful after major work sessions
- Restructures task memories

## Archiving and Long-Term Storage

### When to Archive

Archive tasks when:
- Task is completed (detected by git commit keywords)
- All tests pass
- User explicitly marks as done
- Manual trigger via `/memory:archive`

### Archive Process

1. **Extract Key Information**:
   - Architecture decisions
   - Technical choices and trade-offs
   - Problem solutions
   - Lessons learned

2. **Store in Multiple Locations**:
   - Move to `archived-tasks/YYYY-MM/`
   - Extract insights to SQLite long-term storage
   - Sync important knowledge to Serena
   - Update CLAUDE.md with static rules

3. **Update Metadata**:
   - Mark task as archived
   - Record archive timestamp
   - Update task statistics

### Long-Term Knowledge Extraction

The context-analyzer agent extracts:
- **Decisions**: Why certain approaches were chosen
- **Solutions**: How problems were solved
- **Patterns**: Recurring themes and best practices
- **Lessons**: What worked and what didn't

Stored in SQLite with:
- Full-text search capability
- Topic categorization
- Importance scoring
- Access tracking

## Integration with Other Tools

### CLAUDE.md Synchronization

**What Goes to CLAUDE.md**:
- Static project rules (code style, structure)
- Development workflows
- Tool configurations
- Fixed conventions

**What Stays in Memory Manager**:
- Dynamic knowledge (decisions, solutions)
- Session history
- Task progress
- Temporary context

**Sync Strategy**:
- Automatic sync on task archive
- Only sync static rules to CLAUDE.md
- Dynamic knowledge goes to Serena

### Serena MCP Integration

**When Serena Loads**:
- New task starts
- 7+ days since last load
- Serena has updates
- User explicitly requests

**What Serena Provides**:
- Project-level knowledge
- Architecture decisions
- Technical choices
- Problem solutions

**What Memory Manager Provides to Serena**:
- Extracted insights from archived tasks
- Important decisions and rationale
- Lessons learned
- Best practices discovered

### Git Integration

**Memory Triggers from Git**:
- Commit messages analyzed for task completion
- Keywords: "完成", "finish", "done", "complete"
- Triggers archive prompt

**Git as Memory Marker**:
- Commits mark progress milestones
- Tags can mark major achievements
- Branch names can indicate task context

## Best Practices

### Task Naming

Use descriptive, kebab-case names:
- ✅ `api-authentication`
- ✅ `database-migration`
- ✅ `frontend-redesign`
- ❌ `task1`
- ❌ `fix`
- ❌ `temp`

### Session Boundaries

Start new sessions for:
- Different work days
- Major context switches
- After long breaks
- Different subtasks

### Archive Timing

Archive promptly when:
- Task is truly complete
- All related work is done
- Tests pass and code is merged
- No pending follow-ups

Don't archive if:
- Might need to continue soon
- Waiting for review/feedback
- Related tasks pending

### Search Strategies

**For Recent Work**:
- Use time-range search
- Search within active tasks
- Check recent sessions first

**For Historical Knowledge**:
- Search long-term SQLite
- Query Serena for project knowledge
- Use topic-based search

**For Specific Details**:
- Use role-based search (user queries)
- Search by file paths
- Use exact phrase matching

## Commands Reference

Quick reference for memory commands:

| Command | Purpose | Example |
|---------|---------|---------|
| `/memory:save` | Save current session | `/memory:save` |
| `/memory:load` | Load task/session | `/memory:load task-001` |
| `/memory:search` | Search memories | `/memory:search "auth"` |
| `/memory:organize` | Organize task memories | `/memory:organize` |
| `/memory:export` | Export memories | `/memory:export --format json` |
| `/memory:stats` | View statistics | `/memory:stats` |
| `/memory:compact` | Manual compact | `/memory:compact` |
| `/memory:archive` | Archive task | `/memory:archive task-001` |

## Additional Resources

### Reference Files

For detailed information, consult:
- **`references/sqlite-schema.md`** - Complete database schema and queries
- **`references/serena-integration.md`** - Serena MCP integration details
- **`references/compact-algorithm.md`** - Compression algorithm explanation

### Example Files

Working examples in `examples/`:
- **`task-structure.json`** - Example task metadata
- **`session-record.json`** - Example session format
- **`search-queries.sh`** - Common search patterns

### Utility Scripts

Helper scripts in `scripts/`:
- **`init-memory.sh`** - Initialize memory structure
- **`query-memory.py`** - Query SQLite database
- **`export-task.sh`** - Export task to various formats

## Troubleshooting

**Memory not loading on startup**:
- Check `.claude/memory/` directory exists
- Verify SessionStart hook is active
- Check for corrupted JSON files

**Search not finding results**:
- Verify SQLite FTS5 index is built
- Check search syntax
- Try broader search terms

**Archive failing**:
- Ensure task is in active-tasks/
- Check disk space
- Verify SQLite database is accessible

**Context growing too large**:
- Trigger manual compact: `/memory:compact`
- Archive completed tasks
- Check compression threshold setting

For more troubleshooting, see `references/troubleshooting.md`.
