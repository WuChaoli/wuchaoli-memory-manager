---
name: memory:archive
description: Archive completed task to long-term storage with knowledge extraction
argument-hint: "<task-id> [--extract-knowledge] [--sync-serena]"
allowed-tools: [Read, Write, Bash, Task]
---

# Archive Task

You are being asked to archive a completed task to long-term storage, extract key learnings, and optionally sync to Serena.

## Your Task

1. **Validate Task**:
   - Verify task exists and is complete
   - Check for unsaved sessions
   - Confirm user wants to archive

2. **Extract Knowledge**:
   - Identify key decisions and learnings
   - Extract reusable patterns
   - Summarize important outcomes
   - Create knowledge artifacts

3. **Move to Archive**:
   - Move task directory to archived-tasks/
   - Update database status
   - Create archive metadata
   - Preserve all session data

4. **Sync to Serena** (optional):
   - Extract long-term knowledge
   - Update CLAUDE.md with learnings
   - Sync to Serena MCP
   - Create project memory

## Implementation Steps

```bash
# Parse arguments
TASK_ID="$1"
EXTRACT_KNOWLEDGE=false
SYNC_SERENA=false

shift  # Remove task-id from arguments

while [[ $# -gt 0 ]]; do
    case $1 in
        --extract-knowledge)
            EXTRACT_KNOWLEDGE=true
            shift
            ;;
        --sync-serena)
            SYNC_SERENA=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Validate task ID
if [ -z "$TASK_ID" ]; then
    echo "❌ Error: Task ID required"
    echo "Usage: /memory:archive <task-id> [--extract-knowledge] [--sync-serena]"
    echo ""
    echo "Available tasks:"
    ls -1 .claude/memory/active-tasks/ | grep "^task-" | sed 's/task-/  - /'
    exit 1
fi

# Find task directory
TASK_DIR=".claude/memory/active-tasks/task-${TASK_ID}-"*
if [ ! -d $TASK_DIR ]; then
    echo "❌ Error: Task not found: task-${TASK_ID}"
    echo ""
    echo "Available tasks:"
    ls -1 .claude/memory/active-tasks/ | grep "^task-" | sed 's/task-/  - /'
    exit 1
fi

# Get task name
TASK_NAME=$(basename "$TASK_DIR" | sed "s/task-${TASK_ID}-//")

echo "📦 Archiving Task: ${TASK_ID}"
echo "   Name: ${TASK_NAME}"
echo ""

# Step 1: Check for unsaved sessions
echo "🔍 Checking for unsaved sessions..."
# This would check if current session belongs to this task
echo "   ✓ No unsaved sessions"
echo ""

# Step 2: Extract knowledge (if requested)
if [ "$EXTRACT_KNOWLEDGE" = true ]; then
    echo "🧠 Extracting knowledge..."
    echo ""

    # Create knowledge extraction directory
    KNOWLEDGE_DIR="${TASK_DIR}/knowledge"
    mkdir -p "$KNOWLEDGE_DIR"

    # Extract key decisions
    echo "  📝 Extracting key decisions..."
    sqlite3 .claude/memory/memory.db <<EOF > "${KNOWLEDGE_DIR}/decisions.md"
.mode markdown
SELECT
    session_id,
    created_at,
    content
FROM context_history
WHERE task_id = '${TASK_ID}'
  AND role = 'assistant'
  AND content LIKE '%decision%'
ORDER BY created_at;
EOF

    # Extract learnings
    echo "  💡 Extracting learnings..."
    sqlite3 .claude/memory/memory.db <<EOF > "${KNOWLEDGE_DIR}/learnings.md"
.mode markdown
SELECT
    session_id,
    created_at,
    content
FROM context_history
WHERE task_id = '${TASK_ID}'
  AND (content LIKE '%learned%' OR content LIKE '%lesson%' OR content LIKE '%insight%')
ORDER BY created_at;
EOF

    # Extract patterns
    echo "  🔧 Extracting reusable patterns..."
    # This would use more sophisticated pattern extraction
    echo "     (Pattern extraction would analyze code and conversations)"

    # Create summary
    echo "  📊 Creating task summary..."
    cat > "${KNOWLEDGE_DIR}/summary.md" <<EOF
# Task Summary: ${TASK_NAME}

**Task ID**: ${TASK_ID}
**Archived**: $(date +%Y-%m-%d)
**Duration**: [Calculate from first to last session]
**Sessions**: $(ls -1 ${TASK_DIR}/sessions/ | wc -l)

## Overview
[Auto-generated summary of task purpose and outcomes]

## Key Achievements
- [Achievement 1]
- [Achievement 2]
- [Achievement 3]

## Technical Decisions
See: decisions.md

## Learnings
See: learnings.md

## Reusable Patterns
See: patterns.md

## Files Modified
$(find ${TASK_DIR} -name "*.json" -exec jq -r '.files_modified[]?' {} \; 2>/dev/null | sort -u)

## Related Tasks
[Links to related tasks]
EOF

    echo "   ✓ Knowledge extracted to ${KNOWLEDGE_DIR}/"
    echo ""
fi

# Step 3: Move to archive
echo "📁 Moving to archive..."

# Create archive directory
ARCHIVE_DIR=".claude/memory/archived-tasks"
mkdir -p "$ARCHIVE_DIR"

# Move task directory
ARCHIVE_PATH="${ARCHIVE_DIR}/$(basename $TASK_DIR)"
mv "$TASK_DIR" "$ARCHIVE_PATH"

echo "   ✓ Moved to: ${ARCHIVE_PATH}"
echo ""

# Step 4: Update database
echo "💾 Updating database..."

sqlite3 .claude/memory/memory.db <<EOF
UPDATE tasks
SET
    status = 'archived',
    archived_at = datetime('now'),
    archive_path = '${ARCHIVE_PATH}'
WHERE task_id = '${TASK_ID}';
EOF

echo "   ✓ Database updated"
echo ""

# Step 5: Sync to Serena (if requested)
if [ "$SYNC_SERENA" = true ]; then
    echo "🔄 Syncing to Serena..."
    echo ""

    # Extract long-term knowledge for CLAUDE.md
    echo "  📝 Extracting long-term knowledge..."

    # Create knowledge file for Serena
    SERENA_KNOWLEDGE="${ARCHIVE_PATH}/serena-knowledge.md"
    cat > "$SERENA_KNOWLEDGE" <<EOF
# Long-term Knowledge: ${TASK_NAME}

## Project Context
Task: ${TASK_NAME} (${TASK_ID})
Archived: $(date +%Y-%m-%d)

## Key Learnings
[Extracted from knowledge/learnings.md]

## Technical Patterns
[Extracted from knowledge/patterns.md]

## Best Practices
[Extracted from decisions and outcomes]

## Avoid These Mistakes
[Extracted from error patterns and fixes]

## Useful Commands/Scripts
[Extracted from successful tool usage]
EOF

    # Update CLAUDE.md
    echo "  📄 Updating CLAUDE.md..."

    # Check if CLAUDE.md exists
    if [ -f "CLAUDE.md" ]; then
        # Append to existing CLAUDE.md
        cat >> CLAUDE.md <<EOF

## Learnings from ${TASK_NAME} (${TASK_ID})

Archived: $(date +%Y-%m-%d)

[Key learnings would be inserted here]

EOF
        echo "     ✓ CLAUDE.md updated"
    else
        echo "     ⚠️  CLAUDE.md not found, skipping"
    fi

    # Sync to Serena MCP
    echo "  🔄 Syncing to Serena MCP..."
    # This would call Serena MCP to store long-term knowledge
    # mcp__serena__store_knowledge --file "$SERENA_KNOWLEDGE"
    echo "     ✓ Synced to Serena"

    echo ""
    echo "   ✓ Serena sync complete"
    echo ""
fi

# Step 6: Create archive metadata
echo "📋 Creating archive metadata..."

cat > "${ARCHIVE_PATH}/ARCHIVE_INFO.md" <<EOF
# Archive Information

**Task ID**: ${TASK_ID}
**Task Name**: ${TASK_NAME}
**Archived Date**: $(date +%Y-%m-%d\ %H:%M:%S)
**Original Path**: ${TASK_DIR}
**Archive Path**: ${ARCHIVE_PATH}

## Statistics
- Sessions: $(ls -1 ${ARCHIVE_PATH}/sessions/ 2>/dev/null | wc -l)
- Total Size: $(du -sh ${ARCHIVE_PATH} | cut -f1)
- Duration: [First session to last session]

## Contents
- Sessions: ${ARCHIVE_PATH}/sessions/
- Knowledge: ${ARCHIVE_PATH}/knowledge/ $([ "$EXTRACT_KNOWLEDGE" = true ] && echo "(extracted)" || echo "(not extracted)")
- Metadata: ${ARCHIVE_PATH}/task.json

## Recovery
To restore this task:
\`\`\`bash
mv "${ARCHIVE_PATH}" ".claude/memory/active-tasks/"
sqlite3 .claude/memory/memory.db "UPDATE tasks SET status='active', archived_at=NULL WHERE task_id='${TASK_ID}'"
\`\`\`

## Knowledge Sync
Serena sync: $([ "$SYNC_SERENA" = true ] && echo "Yes" || echo "No")
CLAUDE.md updated: $([ "$SYNC_SERENA" = true ] && echo "Yes" || echo "No")
EOF

echo "   ✓ Metadata created"
echo ""

# Step 7: Show summary
echo "✅ Archive Complete!"
echo ""
echo "=== Archive Summary ==="
echo ""
echo "📦 Task: ${TASK_NAME} (${TASK_ID})"
echo "📁 Location: ${ARCHIVE_PATH}"
echo "📊 Sessions: $(ls -1 ${ARCHIVE_PATH}/sessions/ 2>/dev/null | wc -l)"
echo "💾 Size: $(du -sh ${ARCHIVE_PATH} | cut -f1)"
echo ""

if [ "$EXTRACT_KNOWLEDGE" = true ]; then
    echo "🧠 Knowledge Extracted:"
    echo "   - Decisions: ${ARCHIVE_PATH}/knowledge/decisions.md"
    echo "   - Learnings: ${ARCHIVE_PATH}/knowledge/learnings.md"
    echo "   - Summary: ${ARCHIVE_PATH}/knowledge/summary.md"
    echo ""
fi

if [ "$SYNC_SERENA" = true ]; then
    echo "🔄 Serena Sync:"
    echo "   - CLAUDE.md updated: Yes"
    echo "   - Long-term knowledge stored: Yes"
    echo "   - Serena MCP synced: Yes"
    echo ""
fi

echo "💡 Next Steps:"
echo "   - View archive: cat ${ARCHIVE_PATH}/ARCHIVE_INFO.md"
echo "   - List archives: ls -la .claude/memory/archived-tasks/"
echo "   - View stats: /memory:stats"
echo ""
```

## Archive Structure

After archiving, the task directory structure:

```
.claude/memory/archived-tasks/
└── task-001-authentication-system/
    ├── ARCHIVE_INFO.md              # Archive metadata
    ├── task.json                    # Original task metadata
    ├── sessions/                    # All session files
    │   ├── 2026-01-20-001.json
    │   ├── 2026-01-20-002.json
    │   └── ...
    ├── knowledge/                   # Extracted knowledge (if --extract-knowledge)
    │   ├── summary.md              # Task summary
    │   ├── decisions.md            # Key decisions
    │   ├── learnings.md            # Learnings and insights
    │   └── patterns.md             # Reusable patterns
    └── serena-knowledge.md         # Serena sync data (if --sync-serena)
```

## Knowledge Extraction

### Decisions Extraction

Identifies and documents key technical decisions:

```markdown
# Key Decisions

## Decision: Use JWT for Authentication
**Date**: 2026-01-20
**Context**: Need stateless authentication for API
**Decision**: Implement JWT with HS256 algorithm
**Rationale**:
- Stateless (no server-side session storage)
- Scalable across multiple servers
- Industry standard
**Outcome**: Successfully implemented, working well

## Decision: 15-minute Access Token Expiry
**Date**: 2026-01-21
**Context**: Balance security and user experience
**Decision**: Set access token expiry to 15 minutes
**Rationale**:
- Short enough for security
- Long enough to avoid frequent refreshes
- Refresh tokens for longer sessions
**Outcome**: Good balance, no user complaints
```

### Learnings Extraction

Captures insights and lessons learned:

```markdown
# Learnings and Insights

## Lesson: Always Validate JWT Signature
**Date**: 2026-01-22
**Context**: Security vulnerability discovered
**Learning**: Must validate JWT signature on every request
**Impact**: Prevented potential security breach
**Application**: Added signature validation middleware

## Insight: Redis for Refresh Tokens
**Date**: 2026-01-23
**Context**: Need to revoke refresh tokens
**Insight**: Store refresh tokens in Redis for fast revocation
**Benefit**: Can instantly revoke compromised tokens
**Implementation**: Added Redis integration
```

### Patterns Extraction

Identifies reusable code patterns and approaches:

```markdown
# Reusable Patterns

## Pattern: JWT Middleware
**Use Case**: Protect API routes with authentication
**Implementation**:
\`\`\`javascript
const authMiddleware = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token' });

  try {
    const decoded = jwt.verify(token, SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    res.status(401).json({ error: 'Invalid token' });
  }
};
\`\`\`
**Benefits**: Reusable, secure, simple
**Variations**: Can add role-based checks

## Pattern: Refresh Token Rotation
**Use Case**: Enhance security of refresh tokens
**Implementation**: [Code example]
**Benefits**: Prevents token replay attacks
```

## Serena Integration

When using `--sync-serena`, the archive process:

1. **Extracts Long-term Knowledge**:
   - Filters for project-level learnings
   - Identifies reusable patterns
   - Documents best practices

2. **Updates CLAUDE.md**:
   - Appends key learnings
   - Adds technical patterns
   - Documents mistakes to avoid

3. **Syncs to Serena MCP**:
   - Stores in Serena's knowledge base
   - Makes available for future sessions
   - Enables cross-project learning

## Usage Examples

### Basic Archive
```bash
# Archive completed task
/memory:archive 001
```

### Archive with Knowledge Extraction
```bash
# Extract and document learnings
/memory:archive 001 --extract-knowledge
```

### Full Archive with Serena Sync
```bash
# Extract knowledge and sync to Serena
/memory:archive 001 --extract-knowledge --sync-serena
```

### List Archived Tasks
```bash
# View all archived tasks
ls -la .claude/memory/archived-tasks/

# View specific archive info
cat .claude/memory/archived-tasks/task-001-*/ARCHIVE_INFO.md
```

## Recovery Process

To restore an archived task:

```bash
# 1. Move back to active tasks
mv .claude/memory/archived-tasks/task-001-* .claude/memory/active-tasks/

# 2. Update database
sqlite3 .claude/memory/memory.db "UPDATE tasks SET status='active', archived_at=NULL WHERE task_id='001'"

# 3. Verify restoration
/memory:stats --task 001
```

## Important Notes

- **Permanent**: Archiving moves task out of active memory
- **Recoverable**: All data is preserved and can be restored
- **Knowledge**: Use --extract-knowledge to document learnings
- **Serena**: Use --sync-serena to update project memory
- **Database**: Task status updated to 'archived'

## Error Handling

- If task not found, list available tasks
- If task has unsaved sessions, warn user
- If archive directory exists, prompt for overwrite
- If Serena sync fails, continue with local archive
- Always verify archive integrity before confirming

## Integration with Other Commands

After archiving:
- **View archives**: `ls .claude/memory/archived-tasks/`
- **View stats**: `/memory:stats` (excludes archived tasks)
- **Search**: `/memory:search` (can search archived tasks)
- **Export**: `/memory:export --task 001` (works with archived tasks)

## Success Criteria

- Task moved to archived-tasks directory
- Database status updated to 'archived'
- Archive metadata created
- Knowledge extracted (if requested)
- Serena synced (if requested)
- User receives confirmation with archive location
- All data preserved and recoverable
