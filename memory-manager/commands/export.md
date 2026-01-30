---
name: memory:export
description: Export memory data in various formats (JSON, Markdown, CSV)
argument-hint: "[--format FORMAT] [--task TASK_ID] [--output FILE]"
allowed-tools: [Read, Write, Bash]
---

# Export Memory

You are being asked to export memory data from the database in various formats for backup, analysis, or sharing.

## Your Task

1. **Parse Export Parameters**:
   - Format: json, markdown, csv, html
   - Task filter: specific task or all tasks
   - Output file: destination path
   - Date range: optional time filter

2. **Query Database**:
   - Retrieve requested data
   - Apply filters (task, date, role)
   - Include metadata
   - Preserve structure

3. **Format Output**:
   - Convert to requested format
   - Apply formatting rules
   - Include headers and metadata
   - Ensure readability

4. **Save Export**:
   - Write to specified file
   - Create directory if needed
   - Verify export success
   - Provide download link

## Implementation Steps

```bash
# Parse arguments
FORMAT="json"
TASK_ID=""
OUTPUT_FILE=""
FROM_DATE=""
TO_DATE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --task)
            TASK_ID="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --from)
            FROM_DATE="$2"
            shift 2
            ;;
        --to)
            TO_DATE="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Validate format
case $FORMAT in
    json|markdown|md|csv|html)
        ;;
    *)
        echo "❌ Invalid format: $FORMAT"
        echo "Supported formats: json, markdown, csv, html"
        exit 1
        ;;
esac

# Normalize format
if [ "$FORMAT" = "md" ]; then
    FORMAT="markdown"
fi

echo "📤 Exporting Memory Data..."
echo ""

# Check database
DB_PATH=".claude/memory/memory.db"
if [ ! -f "$DB_PATH" ]; then
    echo "❌ Memory database not found. Run /memory:save first."
    exit 1
fi

# Build filter
FILTER=""
if [ -n "$TASK_ID" ]; then
    FILTER="WHERE task_id = '${TASK_ID}'"
    echo "   Scope: Task ${TASK_ID}"
else
    echo "   Scope: All tasks"
fi

if [ -n "$FROM_DATE" ]; then
    if [ -n "$FILTER" ]; then
        FILTER="$FILTER AND created_at >= '${FROM_DATE}'"
    else
        FILTER="WHERE created_at >= '${FROM_DATE}'"
    fi
    echo "   From: ${FROM_DATE}"
fi

if [ -n "$TO_DATE" ]; then
    if [ -n "$FILTER" ]; then
        FILTER="$FILTER AND created_at <= '${TO_DATE}'"
    else
        FILTER="WHERE created_at <= '${TO_DATE}'"
    fi
    echo "   To: ${TO_DATE}"
fi

echo "   Format: ${FORMAT}"
echo ""

# Generate output filename if not provided
if [ -z "$OUTPUT_FILE" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    if [ -n "$TASK_ID" ]; then
        OUTPUT_FILE="memory_export_task${TASK_ID}_${TIMESTAMP}.${FORMAT}"
    else
        OUTPUT_FILE="memory_export_${TIMESTAMP}.${FORMAT}"
    fi
fi

echo "   Output: ${OUTPUT_FILE}"
echo ""

# Create export directory
EXPORT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$EXPORT_DIR"

# Export based on format
echo "⚙️  Exporting data..."
echo ""

case $FORMAT in
    json)
        # Export as JSON
        sqlite3 "$DB_PATH" <<EOF > "$OUTPUT_FILE"
.mode json
SELECT
    ch.id,
    ch.session_id,
    ch.task_id,
    t.name as task_name,
    ch.role,
    ch.content,
    ch.context_size,
    ch.context_position,
    ch.created_at,
    GROUP_CONCAT(tp.topic, ', ') as topics
FROM context_history ch
LEFT JOIN tasks t ON ch.task_id = t.task_id
LEFT JOIN topics tp ON ch.session_id = tp.session_id
${FILTER}
GROUP BY ch.id
ORDER BY ch.created_at;
EOF
        echo "   ✓ JSON export complete"
        ;;

    markdown)
        # Export as Markdown
        cat > "$OUTPUT_FILE" <<EOF
# Memory Export

**Generated**: $(date +"%Y-%m-%d %H:%M:%S")
**Format**: Markdown
$([ -n "$TASK_ID" ] && echo "**Task**: ${TASK_ID}")
$([ -n "$FROM_DATE" ] && echo "**From**: ${FROM_DATE}")
$([ -n "$TO_DATE" ] && echo "**To**: ${TO_DATE}")

---

EOF

        # Export sessions
        sqlite3 "$DB_PATH" <<EOSQL >> "$OUTPUT_FILE"
.mode markdown
.headers on

-- Task Summary
SELECT
    task_id as "Task ID",
    name as "Task Name",
    status as "Status",
    session_count as "Sessions",
    memory_size as "Size (bytes)",
    created_at as "Created"
FROM tasks
$([ -n "$TASK_ID" ] && echo "WHERE task_id = '${TASK_ID}'")
ORDER BY created_at DESC;
EOSQL

        echo "" >> "$OUTPUT_FILE"
        echo "## Sessions" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"

        # Export session details
        SESSIONS=$(sqlite3 "$DB_PATH" "SELECT DISTINCT session_id FROM context_history ${FILTER} ORDER BY created_at;")

        for SESSION in $SESSIONS; do
            echo "### Session: $SESSION" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"

            sqlite3 "$DB_PATH" <<EOSQL >> "$OUTPUT_FILE"
.mode list
SELECT
    '**Date**: ' || created_at || '  '
FROM context_history
WHERE session_id = '$SESSION'
LIMIT 1;

SELECT
    '**Task**: ' || task_id || '  '
FROM context_history
WHERE session_id = '$SESSION'
LIMIT 1;

SELECT
    '**Messages**: ' || COUNT(*) || '  '
FROM context_history
WHERE session_id = '$SESSION';
EOSQL

            echo "" >> "$OUTPUT_FILE"
            echo "#### Messages" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"

            sqlite3 "$DB_PATH" <<EOSQL >> "$OUTPUT_FILE"
.mode list
SELECT
    '**' || role || '** (' || created_at || '):  ' || CHAR(10) || content || CHAR(10)
FROM context_history
WHERE session_id = '$SESSION'
ORDER BY context_position;
EOSQL

            echo "" >> "$OUTPUT_FILE"
            echo "---" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        done

        echo "   ✓ Markdown export complete"
        ;;

    csv)
        # Export as CSV
        sqlite3 "$DB_PATH" <<EOF > "$OUTPUT_FILE"
.mode csv
.headers on
SELECT
    ch.id,
    ch.session_id,
    ch.task_id,
    t.name as task_name,
    ch.role,
    ch.content,
    ch.context_size,
    ch.context_position,
    ch.created_at
FROM context_history ch
LEFT JOIN tasks t ON ch.task_id = t.task_id
${FILTER}
ORDER BY ch.created_at;
EOF
        echo "   ✓ CSV export complete"
        ;;

    html)
        # Export as HTML
        cat > "$OUTPUT_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Memory Export</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .header {
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .session {
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .message {
            padding: 15px;
            margin: 10px 0;
            border-left: 4px solid #007bff;
            background: #f8f9fa;
        }
        .message.user {
            border-left-color: #28a745;
        }
        .message.assistant {
            border-left-color: #007bff;
        }
        .message.system {
            border-left-color: #ffc107;
        }
        .meta {
            color: #666;
            font-size: 0.9em;
            margin-bottom: 10px;
        }
        .content {
            white-space: pre-wrap;
            word-wrap: break-word;
        }
        h1, h2, h3 {
            color: #333;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #f8f9fa;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Memory Export</h1>
        <p><strong>Generated:</strong> $(date +"%Y-%m-%d %H:%M:%S")</p>
        $([ -n "$TASK_ID" ] && echo "<p><strong>Task:</strong> ${TASK_ID}</p>")
        $([ -n "$FROM_DATE" ] && echo "<p><strong>From:</strong> ${FROM_DATE}</p>")
        $([ -n "$TO_DATE" ] && echo "<p><strong>To:</strong> ${TO_DATE}</p>")
    </div>

    <div class="session">
        <h2>Task Summary</h2>
        <table>
            <thead>
                <tr>
                    <th>Task ID</th>
                    <th>Name</th>
                    <th>Status</th>
                    <th>Sessions</th>
                    <th>Size</th>
                    <th>Created</th>
                </tr>
            </thead>
            <tbody>
EOF

        # Add task rows
        sqlite3 "$DB_PATH" <<EOSQL >> "$OUTPUT_FILE"
.mode html
SELECT
    task_id,
    name,
    status,
    session_count,
    memory_size,
    created_at
FROM tasks
$([ -n "$TASK_ID" ] && echo "WHERE task_id = '${TASK_ID}'")
ORDER BY created_at DESC;
EOSQL

        cat >> "$OUTPUT_FILE" <<EOF
            </tbody>
        </table>
    </div>
EOF

        # Add sessions
        SESSIONS=$(sqlite3 "$DB_PATH" "SELECT DISTINCT session_id FROM context_history ${FILTER} ORDER BY created_at;")

        for SESSION in $SESSIONS; do
            TASK=$(sqlite3 "$DB_PATH" "SELECT task_id FROM context_history WHERE session_id = '$SESSION' LIMIT 1;")
            DATE=$(sqlite3 "$DB_PATH" "SELECT created_at FROM context_history WHERE session_id = '$SESSION' LIMIT 1;")
            COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM context_history WHERE session_id = '$SESSION';")

            cat >> "$OUTPUT_FILE" <<EOF
    <div class="session">
        <h3>Session: $SESSION</h3>
        <div class="meta">
            <strong>Task:</strong> $TASK |
            <strong>Date:</strong> $DATE |
            <strong>Messages:</strong> $COUNT
        </div>
EOF

            # Add messages
            sqlite3 "$DB_PATH" "SELECT role, content, created_at FROM context_history WHERE session_id = '$SESSION' ORDER BY context_position;" | \
            while IFS='|' read -r role content created_at; do
                cat >> "$OUTPUT_FILE" <<EOF
        <div class="message $role">
            <div class="meta"><strong>$role</strong> - $created_at</div>
            <div class="content">$content</div>
        </div>
EOF
            done

            echo "    </div>" >> "$OUTPUT_FILE"
        done

        cat >> "$OUTPUT_FILE" <<EOF
</body>
</html>
EOF
        echo "   ✓ HTML export complete"
        ;;
esac

echo ""
echo "✅ Export Complete!"
echo ""

# Show statistics
FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
RECORD_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM context_history ${FILTER};")

echo "=== Export Summary ==="
echo ""
echo "📄 File: ${OUTPUT_FILE}"
echo "📊 Size: ${FILE_SIZE}"
echo "📝 Lines: ${LINE_COUNT}"
echo "💾 Records: ${RECORD_COUNT}"
echo ""

# Show preview
echo "📋 Preview (first 10 lines):"
echo "---"
head -10 "$OUTPUT_FILE"
echo "---"
echo ""

echo "💡 Next Steps:"
echo "   - View file: cat ${OUTPUT_FILE}"
echo "   - Open in editor: code ${OUTPUT_FILE}"
if [ "$FORMAT" = "html" ]; then
    echo "   - Open in browser: open ${OUTPUT_FILE}"
fi
echo "   - Share or backup the exported file"
echo ""
```

## Export Formats

### JSON Format

Structured data format, ideal for programmatic access:

```json
[
  {
    "id": 1,
    "session_id": "2026-01-29-001",
    "task_id": "001",
    "task_name": "Authentication System",
    "role": "user",
    "content": "Implement JWT authentication",
    "context_size": 45000,
    "context_position": 0,
    "created_at": "2026-01-29 14:00:00",
    "topics": "Authentication, JWT, Security"
  },
  ...
]
```

### Markdown Format

Human-readable format, ideal for documentation:

```markdown
# Memory Export

**Generated**: 2026-01-29 16:30:00
**Task**: 001

---

| Task ID | Task Name | Status | Sessions | Size | Created |
|---------|-----------|--------|----------|------|---------|
| 001 | Authentication System | active | 8 | 890000 | 2026-01-20 |

## Sessions

### Session: 2026-01-29-001

**Date**: 2026-01-29 14:00:00
**Task**: 001
**Messages**: 28

#### Messages

**user** (2026-01-29 14:00:00):
Implement JWT authentication

**assistant** (2026-01-29 14:01:00):
I'll help you implement JWT authentication...

---
```

### CSV Format

Spreadsheet-compatible format, ideal for analysis:

```csv
id,session_id,task_id,task_name,role,content,context_size,context_position,created_at
1,2026-01-29-001,001,Authentication System,user,"Implement JWT authentication",45000,0,2026-01-29 14:00:00
2,2026-01-29-001,001,Authentication System,assistant,"I'll help you implement...",45000,1,2026-01-29 14:01:00
```

### HTML Format

Web-viewable format, ideal for sharing:

- Styled, responsive layout
- Color-coded by role
- Searchable in browser
- Printable

## Usage Examples

### Basic Export
```bash
# Export all memory as JSON
/memory:export

# Export as Markdown
/memory:export --format markdown

# Export as CSV
/memory:export --format csv

# Export as HTML
/memory:export --format html
```

### Task-Specific Export
```bash
# Export specific task
/memory:export --task 001

# Export task as Markdown
/memory:export --task 001 --format markdown
```

### Custom Output File
```bash
# Specify output file
/memory:export --output exports/backup.json

# Export to specific location
/memory:export --task 001 --output ~/Documents/task001.md
```

### Date Range Export
```bash
# Export last week
/memory:export --from 2026-01-22

# Export specific date range
/memory:export --from 2026-01-01 --to 2026-01-15

# Export recent data for specific task
/memory:export --task 001 --from 2026-01-20 --format markdown
```

### Combined Filters
```bash
# Complex export
/memory:export --task 001 --from 2026-01-20 --to 2026-01-29 --format html --output reports/task001_jan.html
```

## Export Use Cases

### 1. Backup
```bash
# Daily backup
/memory:export --format json --output backups/memory_$(date +%Y%m%d).json

# Weekly backup with compression
/memory:export --format json --output backups/weekly.json
gzip backups/weekly.json
```

### 2. Documentation
```bash
# Export task documentation
/memory:export --task 001 --format markdown --output docs/task001.md

# Export project history
/memory:export --format markdown --output PROJECT_HISTORY.md
```

### 3. Analysis
```bash
# Export for data analysis
/memory:export --format csv --output analysis/data.csv

# Import into spreadsheet or database
```

### 4. Sharing
```bash
# Export for team review
/memory:export --task 001 --format html --output share/task001_review.html

# Share via email or web
```

### 5. Migration
```bash
# Export for migration to another system
/memory:export --format json --output migration/full_export.json

# Import into new system
```

## Important Notes

- **Complete**: Exports include all metadata and content
- **Filtered**: Apply filters to export specific data
- **Formatted**: Output is properly formatted and readable
- **Portable**: Exported files can be shared or archived
- **Reversible**: JSON exports can be re-imported

## Error Handling

- If database doesn't exist, show setup instructions
- If output directory doesn't exist, create it
- If file exists, prompt for overwrite
- If export fails, show error and suggest fixes
- Validate format before exporting

## Integration with Other Commands

After exporting:
- **Backup**: Store exported files safely
- **Share**: Send to team members
- **Analyze**: Import into analysis tools
- **Document**: Use Markdown exports for docs
- **Migrate**: Use JSON exports for migration

## Success Criteria

- Data exported successfully in requested format
- All filters applied correctly
- Output file created at specified location
- Export summary displayed with statistics
- File is valid and can be opened/imported
- User receives confirmation and next steps
