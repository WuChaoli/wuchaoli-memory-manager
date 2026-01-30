---
name: memory:save
description: Save current session to memory database
argument-hint: "[task-id]"
allowed-tools: [Read, Write, Bash]
---

# Save Current Session

You are being asked to save the current Claude Code session to the memory database.

## Your Task

1. **Determine Task Context**:
   - Check if a task ID was provided as argument
   - If not, check for active task in `.claude/memory/active-tasks/`
   - If no active task, prompt user to create one or provide task ID

2. **Collect Session Data**:
   - Session ID: Generate from current timestamp (YYYY-MM-DD-NNN format)
   - Task ID: From argument or active task
   - Messages: Recent conversation context
   - Tool calls: Important file operations, git commits, test runs
   - Decisions: Key decisions made in this session

3. **Save to Database**:
   - Use `scripts/query-memory.py` or direct SQLite commands
   - Insert into `context_history` table
   - Update task metadata (session_count, memory_size)
   - Record timestamp and context position

4. **Create Session File**:
   - Save session JSON to `.claude/memory/active-tasks/{task-id}/sessions/`
   - Include: session_id, task_id, started_at, messages, summary
   - Format: `{session-id}.json`

5. **Provide Feedback**:
   - Confirm save success
   - Show session ID and location
   - Display memory usage stats

## Implementation Steps

```bash
# 1. Check for active task
TASK_DIR=".claude/memory/active-tasks"
if [ -d "$TASK_DIR" ]; then
    # Find most recent task or use provided task-id
    TASK_ID="${1:-$(ls -t $TASK_DIR | head -1 | sed 's/task-//' | cut -d'-' -f1)}"
fi

# 2. Generate session ID
SESSION_ID="$(date +%Y-%m-%d)-$(printf '%03d' $(($(ls -1 $TASK_DIR/task-$TASK_ID-*/sessions/ 2>/dev/null | wc -l) + 1)))"

# 3. Create session file
SESSION_FILE="$TASK_DIR/task-$TASK_ID-*/sessions/$SESSION_ID.json"
mkdir -p "$(dirname $SESSION_FILE)"

# 4. Save session data (use Python script or direct SQL)
python3 scripts/save-session.py --task-id "$TASK_ID" --session-id "$SESSION_ID"

# 5. Confirm save
echo "Session saved: $SESSION_ID"
echo "Task: $TASK_ID"
echo "Location: $SESSION_FILE"
```

## Session Data Structure

```json
{
  "session_id": "2026-01-29-001",
  "task_id": "001",
  "started_at": "2026-01-29T14:00:00Z",
  "ended_at": "2026-01-29T15:30:00Z",
  "messages": [
    {
      "role": "user",
      "content": "...",
      "timestamp": "2026-01-29T14:00:00Z"
    },
    {
      "role": "assistant",
      "content": "...",
      "timestamp": "2026-01-29T14:01:00Z"
    }
  ],
  "tool_calls": [
    {
      "tool": "Write",
      "file": "src/api/auth.py",
      "timestamp": "2026-01-29T14:15:00Z"
    }
  ],
  "summary": "Implemented JWT authentication with refresh tokens",
  "key_decisions": [
    "Use HS256 algorithm",
    "Store refresh tokens in Redis",
    "15-minute access token expiry"
  ],
  "files_modified": [
    "src/api/auth.py",
    "src/middleware/auth.js"
  ],
  "context_size": 45000
}
```

## Important Notes

- **Auto-save**: This command is also triggered automatically by PostToolUse hook
- **Incremental**: Only save new content since last save
- **Efficient**: Don't save redundant information
- **Recovery**: Ensure data is recoverable from database

## Error Handling

- If database doesn't exist, run `scripts/init-db.sh` first
- If no active task, prompt user to create one
- If save fails, log error and suggest manual save
- Always verify save success before confirming

## Example Usage

```bash
# Save to current active task
/memory:save

# Save to specific task
/memory:save task-001

# Auto-save after important operation (via hook)
# [Automatically triggered after Write, Edit, Git, Test]
```

## Success Criteria

- Session data saved to SQLite database
- Session JSON file created in task directory
- Task metadata updated
- User receives confirmation with session ID
- Memory stats displayed
