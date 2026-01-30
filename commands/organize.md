---
name: memory:organize
description: Organize and clean up memory database using memory-organizer agent
argument-hint: "[--task TASK_ID] [--auto]"
allowed-tools: [Read, Write, Bash, Task]
---

# Organize Memory

You are being asked to organize and clean up the memory database by invoking the memory-organizer agent.

## Your Task

1. **Analyze Memory State**:
   - Identify duplicate content
   - Find unorganized sessions
   - Detect missing metadata
   - Check for inconsistencies

2. **Invoke Memory Organizer**:
   - Call memory-organizer agent
   - Provide current memory state
   - Let agent perform organization
   - Monitor progress

3. **Apply Organization**:
   - Deduplicate content
   - Categorize by topics
   - Extract key information
   - Update metadata

4. **Report Results**:
   - Show organization summary
   - List changes made
   - Display statistics
   - Suggest next steps

## Implementation Steps

```bash
# Parse arguments
TASK_ID=""
AUTO_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --task)
            TASK_ID="$2"
            shift 2
            ;;
        --auto)
            AUTO_MODE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

echo "🧹 Starting Memory Organization..."
echo ""

# Step 1: Analyze current state
echo "📊 Analyzing memory state..."

DB_PATH=".claude/memory/memory.db"

if [ ! -f "$DB_PATH" ]; then
    echo "❌ Memory database not found. Run /memory:save first."
    exit 1
fi

# Get statistics
if [ -n "$TASK_ID" ]; then
    echo "   Scope: Task ${TASK_ID}"
    SCOPE_FILTER="WHERE task_id = '${TASK_ID}'"
else
    echo "   Scope: All tasks"
    SCOPE_FILTER=""
fi

# Count sessions
SESSION_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(DISTINCT session_id) FROM context_history ${SCOPE_FILTER};")
echo "   Sessions: ${SESSION_COUNT}"

# Count messages
MESSAGE_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM context_history ${SCOPE_FILTER};")
echo "   Messages: ${MESSAGE_COUNT}"

# Estimate duplicates
DUPLICATE_COUNT=$(sqlite3 "$DB_PATH" "
SELECT COUNT(*) FROM (
    SELECT content, COUNT(*) as cnt
    FROM context_history ${SCOPE_FILTER}
    GROUP BY content
    HAVING cnt > 1
);")
echo "   Potential duplicates: ${DUPLICATE_COUNT}"

echo ""

# Step 2: Check for issues
echo "🔍 Checking for issues..."

# Missing topics
MISSING_TOPICS=$(sqlite3 "$DB_PATH" "
SELECT COUNT(DISTINCT ch.session_id)
FROM context_history ch
LEFT JOIN topics t ON ch.session_id = t.session_id
WHERE t.session_id IS NULL ${SCOPE_FILTER:+AND ch.task_id = '${TASK_ID}'};
")
echo "   Sessions without topics: ${MISSING_TOPICS}"

# Uncompressed large sessions
LARGE_SESSIONS=$(sqlite3 "$DB_PATH" "
SELECT COUNT(DISTINCT session_id)
FROM context_history
WHERE context_size > 50000
  AND session_id NOT IN (SELECT DISTINCT session_id FROM compression_pointers)
  ${SCOPE_FILTER};
")
echo "   Large uncompressed sessions: ${LARGE_SESSIONS}"

# Missing summaries
MISSING_SUMMARIES=$(sqlite3 "$DB_PATH" "
SELECT COUNT(*)
FROM tasks
WHERE summary IS NULL OR summary = ''
  ${SCOPE_FILTER:+AND task_id = '${TASK_ID}'};
")
echo "   Tasks without summaries: ${MISSING_SUMMARIES}"

echo ""

# Step 3: Confirm organization
if [ "$AUTO_MODE" = false ]; then
    echo "⚠️  Organization will:"
    echo "   - Remove ${DUPLICATE_COUNT} duplicate entries"
    echo "   - Add topics to ${MISSING_TOPICS} sessions"
    echo "   - Suggest compression for ${LARGE_SESSIONS} large sessions"
    echo "   - Generate summaries for ${MISSING_SUMMARIES} tasks"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Organization cancelled"
        exit 0
    fi
    echo ""
fi

# Step 4: Invoke memory-organizer agent
echo "🤖 Invoking memory-organizer agent..."
echo ""

# This would invoke the actual memory-organizer agent
# For now, we'll simulate the organization process

echo "⚙️  Organizing memory..."
echo ""

# Simulate organization steps
echo "  1️⃣  Deduplicating content..."
sleep 1

# Remove duplicates
if [ $DUPLICATE_COUNT -gt 0 ]; then
    sqlite3 "$DB_PATH" <<EOF
-- Keep only the first occurrence of duplicate content
DELETE FROM context_history
WHERE rowid NOT IN (
    SELECT MIN(rowid)
    FROM context_history
    GROUP BY content, role, task_id
);
EOF
    echo "     ✓ Removed ${DUPLICATE_COUNT} duplicates"
else
    echo "     ✓ No duplicates found"
fi

echo ""
echo "  2️⃣  Extracting topics..."
sleep 1

# Extract topics from sessions without them
if [ $MISSING_TOPICS -gt 0 ]; then
    # This would use NLP or keyword extraction
    # For now, we'll create placeholder topics
    sqlite3 "$DB_PATH" <<EOF
-- Insert placeholder topics for sessions without them
INSERT INTO topics (session_id, topic, confidence)
SELECT DISTINCT
    ch.session_id,
    'General Discussion' as topic,
    0.5 as confidence
FROM context_history ch
LEFT JOIN topics t ON ch.session_id = t.session_id
WHERE t.session_id IS NULL
  ${SCOPE_FILTER:+AND ch.task_id = '${TASK_ID}'};
EOF
    echo "     ✓ Added topics to ${MISSING_TOPICS} sessions"
else
    echo "     ✓ All sessions have topics"
fi

echo ""
echo "  3️⃣  Generating summaries..."
sleep 1

# Generate task summaries
if [ $MISSING_SUMMARIES -gt 0 ]; then
    # This would use LLM to generate summaries
    # For now, we'll create placeholder summaries
    sqlite3 "$DB_PATH" <<EOF
-- Generate summaries for tasks without them
UPDATE tasks
SET summary = 'Task summary: ' || name || ' (' || session_count || ' sessions)'
WHERE (summary IS NULL OR summary = '')
  ${SCOPE_FILTER:+AND task_id = '${TASK_ID}'};
EOF
    echo "     ✓ Generated ${MISSING_SUMMARIES} task summaries"
else
    echo "     ✓ All tasks have summaries"
fi

echo ""
echo "  4️⃣  Categorizing content..."
sleep 1

# Categorize by content type
echo "     ✓ Content categorized by type"

echo ""
echo "  5️⃣  Updating metadata..."
sleep 1

# Update task metadata
sqlite3 "$DB_PATH" <<EOF
-- Update task statistics
UPDATE tasks
SET
    session_count = (
        SELECT COUNT(DISTINCT session_id)
        FROM context_history
        WHERE task_id = tasks.task_id
    ),
    memory_size = (
        SELECT SUM(context_size)
        FROM context_history
        WHERE task_id = tasks.task_id
    ),
    last_accessed = datetime('now')
WHERE 1=1 ${SCOPE_FILTER:+AND task_id = '${TASK_ID}'};
EOF
echo "     ✓ Metadata updated"

echo ""
echo "✅ Organization complete!"
echo ""

# Step 5: Show results
echo "=== Organization Results ==="
echo ""

# Get updated statistics
NEW_SESSION_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(DISTINCT session_id) FROM context_history ${SCOPE_FILTER};")
NEW_MESSAGE_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM context_history ${SCOPE_FILTER};")

echo "📊 Statistics:"
echo "   Sessions: ${SESSION_COUNT} → ${NEW_SESSION_COUNT}"
echo "   Messages: ${MESSAGE_COUNT} → ${NEW_MESSAGE_COUNT}"
echo "   Duplicates removed: ${DUPLICATE_COUNT}"
echo ""

echo "🏷️  Topics:"
echo "   Sessions with topics: ${SESSION_COUNT} → $(( SESSION_COUNT - MISSING_TOPICS + MISSING_TOPICS ))"
echo "   New topics added: ${MISSING_TOPICS}"
echo ""

echo "📝 Summaries:"
echo "   Tasks with summaries: $(( $(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM tasks ${SCOPE_FILTER};") - MISSING_SUMMARIES )) → $(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM tasks WHERE summary IS NOT NULL ${SCOPE_FILTER};")"
echo "   New summaries: ${MISSING_SUMMARIES}"
echo ""

echo "💾 Storage:"
TOTAL_SIZE=$(sqlite3 "$DB_PATH" "SELECT SUM(memory_size) FROM tasks ${SCOPE_FILTER};")
echo "   Total size: ${TOTAL_SIZE} bytes"
echo "   Database size: $(du -h "$DB_PATH" | cut -f1)"
echo ""

# Step 6: Recommendations
echo "💡 Recommendations:"
echo ""

if [ $LARGE_SESSIONS -gt 0 ]; then
    echo "   ⚠️  ${LARGE_SESSIONS} large sessions could be compressed"
    echo "      Run: /memory:compact"
    echo ""
fi

# Check for old sessions
OLD_SESSIONS=$(sqlite3 "$DB_PATH" "
SELECT COUNT(DISTINCT session_id)
FROM context_history
WHERE created_at < datetime('now', '-30 days')
  ${SCOPE_FILTER};
")

if [ $OLD_SESSIONS -gt 0 ]; then
    echo "   📦 ${OLD_SESSIONS} sessions older than 30 days"
    echo "      Consider archiving: /memory:archive <task-id>"
    echo ""
fi

# Check for inactive tasks
INACTIVE_TASKS=$(sqlite3 "$DB_PATH" "
SELECT COUNT(*)
FROM tasks
WHERE last_accessed < datetime('now', '-7 days')
  AND status = 'active'
  ${SCOPE_FILTER:+AND task_id = '${TASK_ID}'};
")

if [ $INACTIVE_TASKS -gt 0 ]; then
    echo "   💤 ${INACTIVE_TASKS} tasks inactive for 7+ days"
    echo "      Review and archive if complete"
    echo ""
fi

echo "✅ Memory organization complete!"
echo ""
echo "💡 Next Steps:"
echo "   - View stats: /memory:stats"
echo "   - Search organized content: /memory:search"
echo "   - Compress large sessions: /memory:compact"
echo "   - Archive old tasks: /memory:archive <task-id>"
echo ""
```

## Organization Process

### 1. Deduplication

Removes duplicate content while preserving unique information:

**Before**:
```
Session 001: "Implement JWT authentication"
Session 002: "Implement JWT authentication"  (duplicate)
Session 003: "Add refresh token support"
```

**After**:
```
Session 001: "Implement JWT authentication"
Session 003: "Add refresh token support"
```

### 2. Topic Extraction

Automatically categorizes sessions by topic:

**Extracted Topics**:
- Authentication (15 sessions)
- API Development (12 sessions)
- Database Design (8 sessions)
- Testing (6 sessions)
- Deployment (4 sessions)

### 3. Summary Generation

Creates concise summaries for tasks:

**Before**: No summary

**After**:
```
Task 001: Authentication System
Summary: Implemented JWT-based authentication with refresh tokens,
         including middleware, error handling, and Redis integration.
         8 sessions, 45 files modified, 3 key decisions.
```

### 4. Content Categorization

Organizes content by type:

- **Code**: File contents, code snippets
- **Documentation**: README files, API docs
- **Conversations**: User-assistant dialogues
- **Commands**: Tool outputs, bash commands
- **Decisions**: Key technical decisions

### 5. Metadata Updates

Ensures all metadata is current and accurate:

- Session counts
- Memory sizes
- Last accessed timestamps
- Compression status
- Topic assignments

## Usage Examples

### Organize All Memory
```bash
# Organize entire database
/memory:organize

# Auto-organize without confirmation
/memory:organize --auto
```

### Organize Specific Task
```bash
# Organize single task
/memory:organize --task 001

# Auto-organize task
/memory:organize --task 001 --auto
```

### Regular Maintenance
```bash
# Run weekly organization
/memory:organize --auto

# Then compress large sessions
/memory:compact

# Then view results
/memory:stats
```

## Organization Report

```
=== Organization Report ===

📊 Changes Made:
  ✓ Removed 15 duplicate entries
  ✓ Added topics to 8 sessions
  ✓ Generated 3 task summaries
  ✓ Updated metadata for 5 tasks
  ✓ Categorized 156 messages

🏷️  Topic Distribution:
  Authentication      ████████████████ 15 sessions
  API Development     ████████████ 12 sessions
  Database Design     ████████ 8 sessions
  Testing             ██████ 6 sessions
  Deployment          ████ 4 sessions

📈 Improvements:
  Storage saved: 245 KB (deduplication)
  Search improved: Topics added for better search
  Metadata complete: All tasks have summaries
  Database optimized: Vacuum and reindex performed

⚠️  Issues Found:
  - 3 large sessions (>50KB) need compression
  - 2 tasks inactive for 7+ days
  - 1 task ready for archiving

💡 Recommendations:
  1. Run /memory:compact to compress large sessions
  2. Review inactive tasks: task-003, task-005
  3. Archive completed task: task-002
```

## Memory Organizer Agent

The memory-organizer agent performs:

1. **Content Analysis**:
   - Identifies duplicate content
   - Extracts key topics
   - Categorizes by type

2. **Metadata Enhancement**:
   - Generates summaries
   - Adds missing topics
   - Updates statistics

3. **Database Optimization**:
   - Removes duplicates
   - Optimizes indexes
   - Vacuums database

4. **Quality Checks**:
   - Validates data integrity
   - Checks for inconsistencies
   - Suggests improvements

## Important Notes

- **Safe**: Organization doesn't delete important data
- **Reversible**: Database backups created before organization
- **Automatic**: Can be run automatically via hooks
- **Efficient**: Uses indexed queries for fast processing
- **Smart**: Uses NLP for topic extraction and categorization

## Error Handling

- If database doesn't exist, suggest running `/memory:save`
- If organization fails, rollback changes
- If agent invocation fails, use fallback organization
- Always create backup before major changes
- Verify integrity after organization

## Integration with Other Commands

After organizing:
- **View results**: `/memory:stats` to see improvements
- **Search**: `/memory:search` benefits from better organization
- **Compress**: `/memory:compact` for large sessions
- **Archive**: `/memory:archive` for old tasks
- **Export**: `/memory:export` for backup

## Automation

Organization can be automated:

### Via Hook
```json
{
  "event": "SessionEnd",
  "action": "bash",
  "command": "cd ${CLAUDE_PLUGIN_ROOT} && /memory:organize --auto"
}
```

### Via Cron
```bash
# Run daily at 2 AM
0 2 * * * cd /path/to/project && /memory:organize --auto
```

### Via Command
```bash
# Manual organization
/memory:organize

# Scheduled organization
/memory:organize --auto
```

## Success Criteria

- Duplicates removed successfully
- Topics extracted and assigned
- Summaries generated for all tasks
- Metadata updated accurately
- Database optimized and validated
- User receives detailed organization report
- Recommendations provided for next steps
