---
name: memory:load
description: Load task or session memory into current context
argument-hint: "<task-id|session-id>"
allowed-tools: [Read, Bash]
---

# Load Memory

You are being asked to load a previously saved task or session memory into the current context.

## Your Task

1. **Parse Argument**:
   - Determine if argument is task-id or session-id
   - Task ID format: `task-001`, `001`, or task name
   - Session ID format: `2026-01-29-001`

2. **Locate Memory**:
   - Search in `.claude/memory/active-tasks/` first
   - Then search in `.claude/memory/archived-tasks/`
   - Query SQLite database for session data

3. **Load Memory Data**:
   - Read session JSON file
   - Query context_history from database
   - Load task metadata and context

4. **Display Memory**:
   - Show task information
   - Display session summary
   - List key decisions and files modified
   - Show recent messages (last 10-20)

5. **Warn User**:
   - Loading replaces current context
   - Suggest saving current session first
   - Confirm before proceeding

## Implementation Steps

```bash
# 1. Parse argument
ARG="$1"
if [[ "$ARG" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{3}$ ]]; then
    # Session ID format
    LOAD_TYPE="session"
    SESSION_ID="$ARG"
else
    # Task ID format
    LOAD_TYPE="task"
    TASK_ID="$ARG"
fi

# 2. Find memory location
if [ "$LOAD_TYPE" = "task" ]; then
    # Find task directory
    TASK_DIR=$(find .claude/memory/active-tasks .claude/memory/archived-tasks -name "task-${TASK_ID}-*" -type d | head -1)

    if [ -z "$TASK_DIR" ]; then
        echo "Error: Task not found: $TASK_ID"
        exit 1
    fi

    # Load most recent session
    SESSION_FILE=$(ls -t "$TASK_DIR/sessions/"*.json | head -1)
else
    # Find session file
    SESSION_FILE=$(find .claude/memory -name "${SESSION_ID}.json" | head -1)

    if [ -z "$SESSION_FILE" ]; then
        echo "Error: Session not found: $SESSION_ID"
        exit 1
    fi
fi

# 3. Load and display
cat "$SESSION_FILE" | jq '.'
```

## Display Format

```
=== Memory Loaded ===

Task: api-authentication (task-001)
Status: active
Created: 2026-01-29 10:00:00

Session: 2026-01-29-001
Duration: 1.5 hours
Messages: 45
Files Modified: 3

Summary:
Implemented JWT authentication with refresh tokens.
Added middleware for token validation.
Configured Redis for token storage.

Key Decisions:
- Use HS256 algorithm for JWT signing
- 15-minute access token expiry
- 7-day refresh token expiry
- Store refresh tokens in Redis

Files Modified:
- src/api/auth.py (new)
- src/middleware/auth.js (modified)
- src/config/redis.js (modified)

Recent Messages:
[Last 10 messages from the session]

Context Size: 45,000 tokens
Memory Location: .claude/memory/active-tasks/task-001-api-auth/

=== End of Memory ===
```

## Query from Database

```python
# Use query-memory.py script
python3 scripts/query-memory.py search --task task-001 --limit 50

# Or direct SQL
sqlite3 .claude/memory/long-term/knowledge.db <<EOF
SELECT *
FROM context_history
WHERE task_id = 'task-001'
  AND session_id = '2026-01-29-001'
ORDER BY timestamp ASC;
EOF
```

## Important Notes

- **Context Replacement**: Loading replaces current context
- **Save First**: Recommend saving current session before loading
- **Selective Loading**: Can load specific parts (messages, files, decisions)
- **Serena Integration**: Also load from Serena if available

## Loading Strategy

1. **CLAUDE.md**: Always loaded by Claude Code (automatic)
2. **Recent Session**: Load from SQLite (this command)
3. **Serena Knowledge**: Load if needed (separate command)

## Error Handling

- If memory not found, suggest searching: `/memory:search`
- If database error, check database integrity
- If file corrupted, try loading from database backup
- Always verify loaded data before displaying

## Example Usage

```bash
# Load most recent session of a task
/memory:load task-001

# Load specific session
/memory:load 2026-01-29-001

# Load by task name
/memory:load api-authentication
```

## Success Criteria

- Memory data successfully loaded
- Task and session information displayed
- User understands what was loaded
- Context is ready for continuation
