---
name: memory:stats
description: Display memory database statistics and visualizations
argument-hint: "[--task TASK_ID] [--detailed]"
allowed-tools: [Read, Bash]
---

# Memory Statistics

You are being asked to display statistics about the memory database, including usage, compression, and task information.

## Your Task

1. **Gather Statistics**:
   - Total memory size and count
   - Task statistics (count, sessions per task)
   - Compression statistics (ratio, savings)
   - Storage usage (database size, file count)
   - Time-based statistics (daily/weekly activity)

2. **Query Database**:
   - Use `scripts/query-memory.py --stats`
   - Query compression_stats table
   - Calculate aggregated metrics
   - Retrieve task metadata

3. **Display Visualizations**:
   - Memory usage over time (ASCII chart)
   - Compression ratio by task
   - Session distribution
   - Storage breakdown

4. **Provide Insights**:
   - Identify large tasks
   - Suggest cleanup opportunities
   - Show compression effectiveness
   - Highlight recent activity

## Implementation Steps

```bash
# Check for task-specific stats
TASK_ID=""
DETAILED=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --task)
            TASK_ID="$2"
            shift 2
            ;;
        --detailed)
            DETAILED=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Get database path
DB_PATH=".claude/memory/memory.db"

if [ ! -f "$DB_PATH" ]; then
    echo "❌ Memory database not found. Run /memory:save first."
    exit 1
fi

# Query statistics
if [ -n "$TASK_ID" ]; then
    # Task-specific stats
    python3 scripts/query-memory.py --stats --task "$TASK_ID"
else
    # Global stats
    python3 scripts/query-memory.py --stats
fi

# Display detailed stats if requested
if [ "$DETAILED" = true ]; then
    echo ""
    echo "=== Detailed Statistics ==="
    echo ""

    # Database size
    DB_SIZE=$(du -h "$DB_PATH" | cut -f1)
    echo "📊 Database Size: $DB_SIZE"

    # Table row counts
    echo ""
    echo "📋 Table Row Counts:"
    sqlite3 "$DB_PATH" <<EOF
.mode column
.headers on
SELECT
    'tasks' as table_name, COUNT(*) as row_count FROM tasks
UNION ALL
SELECT 'context_history', COUNT(*) FROM context_history
UNION ALL
SELECT 'compression_pointers', COUNT(*) FROM compression_pointers
UNION ALL
SELECT 'long_term_memories', COUNT(*) FROM long_term_memories;
EOF

    # Storage breakdown
    echo ""
    echo "💾 Storage Breakdown:"
    ACTIVE_TASKS=$(find .claude/memory/active-tasks -type d -name "task-*" 2>/dev/null | wc -l)
    ARCHIVED_TASKS=$(find .claude/memory/archived-tasks -type d -name "task-*" 2>/dev/null | wc -l)
    echo "  Active tasks: $ACTIVE_TASKS"
    echo "  Archived tasks: $ARCHIVED_TASKS"

    # Recent activity
    echo ""
    echo "📅 Recent Activity (Last 7 Days):"
    sqlite3 "$DB_PATH" <<EOF
.mode column
.headers on
SELECT
    DATE(created_at) as date,
    COUNT(*) as sessions,
    SUM(context_size) as total_size
FROM context_history
WHERE created_at >= datetime('now', '-7 days')
GROUP BY DATE(created_at)
ORDER BY date DESC;
EOF
fi
```

## Statistics Output Format

### Basic Statistics

```
=== Memory Statistics ===

📊 Overview:
  Total Tasks: 5
  Total Sessions: 23
  Total Memories: 156
  Database Size: 2.4 MB

💾 Storage:
  Active Tasks: 3
  Archived Tasks: 2
  Session Files: 23
  Average Session Size: 45 KB

🗜️ Compression:
  Total Compressed: 12 sessions
  Compression Ratio: 65% (saved 1.2 MB)
  Pointer Compressions: 45
  Summary Compressions: 18

📈 Activity (Last 7 Days):
  Sessions Created: 8
  Messages Saved: 234
  Files Modified: 67
  Average Daily Sessions: 1.1

🏆 Top Tasks:
  1. task-001: 8 sessions, 890 KB
  2. task-002: 6 sessions, 650 KB
  3. task-003: 5 sessions, 520 KB

⏰ Recent Sessions:
  2026-01-29-003: task-001 (45 KB, 2 hours ago)
  2026-01-29-002: task-002 (38 KB, 5 hours ago)
  2026-01-29-001: task-001 (52 KB, 8 hours ago)
```

### Task-Specific Statistics

```bash
/memory:stats --task 001
```

```
=== Task Statistics: task-001 ===

📋 Task Info:
  Name: Authentication System
  Created: 2026-01-20
  Status: active
  Sessions: 8
  Total Size: 890 KB

📊 Session Breakdown:
  Session ID          | Date       | Size  | Messages | Compressed
  --------------------|------------|-------|----------|------------
  2026-01-29-003      | 2026-01-29 | 45 KB | 28       | No
  2026-01-29-002      | 2026-01-29 | 52 KB | 34       | No
  2026-01-28-001      | 2026-01-28 | 38 KB | 25       | Yes (60%)
  2026-01-27-002      | 2026-01-27 | 41 KB | 29       | Yes (65%)
  ...

🗜️ Compression Stats:
  Compressed Sessions: 5/8 (62.5%)
  Total Saved: 450 KB
  Average Ratio: 63%
  Pointer Count: 23
  Summary Count: 12

📁 Files Modified:
  src/api/auth.py (5 times)
  src/middleware/auth.js (3 times)
  tests/test_auth.py (4 times)
  ...

🔑 Key Topics:
  - JWT authentication (12 mentions)
  - Refresh tokens (8 mentions)
  - Middleware (6 mentions)
  - Error handling (5 mentions)

💡 Insights:
  ✓ Good compression ratio (63% average)
  ⚠️ Consider archiving sessions older than 7 days
  ℹ️ Most active file: src/api/auth.py
```

### Detailed Statistics

```bash
/memory:stats --detailed
```

Includes additional information:
- Database table row counts
- Storage directory breakdown
- Daily activity chart (ASCII)
- Compression effectiveness by type
- Memory usage trends

## ASCII Visualizations

### Memory Usage Over Time

```
Memory Usage (Last 30 Days)

MB
3.0 ┤                                    ╭─
2.5 ┤                              ╭─────╯
2.0 ┤                        ╭─────╯
1.5 ┤                  ╭─────╯
1.0 ┤            ╭─────╯
0.5 ┤      ╭─────╯
0.0 ┼──────╯
    └─────────────────────────────────────
    Jan 1        Jan 15        Jan 29
```

### Compression Ratio by Task

```
Compression Effectiveness

Task    Ratio
001     ████████████████░░░░ 65%
002     ██████████████░░░░░░ 58%
003     ██████████████████░░ 72%
004     ████████████░░░░░░░░ 52%
005     ████████████████░░░░ 68%
```

### Session Distribution

```
Sessions per Task

task-001 ████████████████████ 20
task-002 ███████████████ 15
task-003 ████████████ 12
task-004 ████████ 8
task-005 ██████ 6
```

## Insights and Recommendations

Based on statistics, provide actionable insights:

### Storage Optimization
- **Large tasks**: Suggest archiving tasks over 1 MB
- **Old sessions**: Recommend archiving sessions older than 30 days
- **Low compression**: Identify tasks with poor compression ratios

### Activity Patterns
- **Inactive tasks**: Highlight tasks with no activity in 7+ days
- **Peak usage**: Show most active days/times
- **Growth trends**: Indicate if database is growing rapidly

### Compression Effectiveness
- **Good compression**: Tasks with >60% compression ratio
- **Poor compression**: Tasks with <40% compression ratio
- **Optimization opportunities**: Suggest manual compact for large sessions

## Important Notes

- **Real-time**: Statistics are calculated from current database state
- **Caching**: Consider caching stats for large databases
- **Performance**: Use indexed queries for fast statistics
- **Accuracy**: All sizes and counts are exact, not estimates

## Error Handling

- If database doesn't exist, show setup instructions
- If no data available, suggest running `/memory:save`
- If task not found, list available tasks
- If query fails, show error and suggest database repair

## Integration with Other Commands

After viewing stats, you can:
- **Archive large tasks**: `/memory:archive <task-id>`
- **Compress sessions**: `/memory:compact`
- **Export data**: `/memory:export --task <task-id>`
- **Organize memories**: `/memory:organize`
- **Search content**: `/memory:search --task <task-id>`

## Success Criteria

- Statistics are displayed clearly and accurately
- Visualizations are easy to understand
- Insights are actionable and relevant
- Performance is acceptable even with large databases
- User can quickly understand memory usage and health
