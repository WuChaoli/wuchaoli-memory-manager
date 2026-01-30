---
name: memory:search
description: Search memory database with full-text search and filters
argument-hint: "[query] [--task TASK_ID] [--from DATE] [--to DATE] [--role ROLE]"
allowed-tools: [Read, Bash]
---

# Search Memory Database

You are being asked to search the memory database for specific content, tasks, or time periods.

## Your Task

1. **Parse Search Parameters**:
   - Query string: Full-text search term (optional)
   - --task: Filter by task ID
   - --from: Start date (YYYY-MM-DD format)
   - --to: End date (YYYY-MM-DD format)
   - --role: Filter by role (user, assistant, system)

2. **Execute Search**:
   - Use `scripts/query-memory.py` with appropriate parameters
   - Leverage FTS5 full-text search for query strings
   - Apply filters for task, date range, and role
   - Sort results by relevance or timestamp

3. **Display Results**:
   - Show matching sessions and messages
   - Highlight search terms in context
   - Display metadata (task, date, role)
   - Provide result count and statistics

4. **Offer Actions**:
   - Load a specific session
   - Export search results
   - Refine search with additional filters

## Implementation Steps

```bash
# Parse arguments
QUERY=""
TASK_ID=""
FROM_DATE=""
TO_DATE=""
ROLE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --task)
            TASK_ID="$2"
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
        --role)
            ROLE="$2"
            shift 2
            ;;
        *)
            QUERY="$QUERY $1"
            shift
            ;;
    esac
done

# Trim leading/trailing spaces from query
QUERY=$(echo "$QUERY" | xargs)

# Build query command
CMD="python3 scripts/query-memory.py"

if [ -n "$QUERY" ]; then
    CMD="$CMD --search \"$QUERY\""
fi

if [ -n "$TASK_ID" ]; then
    CMD="$CMD --task \"$TASK_ID\""
fi

if [ -n "$FROM_DATE" ]; then
    CMD="$CMD --from \"$FROM_DATE\""
fi

if [ -n "$TO_DATE" ]; then
    CMD="$CMD --to \"$TO_DATE\""
fi

if [ -n "$ROLE" ]; then
    CMD="$CMD --role \"$ROLE\""
fi

# Execute search
eval $CMD
```

## Search Query Examples

### Full-Text Search
```bash
# Search for "authentication" in all memories
/memory:search authentication

# Search for phrase
/memory:search "JWT token implementation"
```

### Task-Specific Search
```bash
# Search within a specific task
/memory:search --task 001

# Search for content in task
/memory:search authentication --task 001
```

### Date Range Search
```bash
# Search memories from last week
/memory:search --from 2026-01-22

# Search in specific date range
/memory:search --from 2026-01-01 --to 2026-01-15

# Combine with query
/memory:search "bug fix" --from 2026-01-20
```

### Role-Based Search
```bash
# Search only user messages
/memory:search --role user

# Search assistant responses
/memory:search --role assistant

# Combine filters
/memory:search "error" --role assistant --from 2026-01-25
```

### Complex Queries
```bash
# Multi-filter search
/memory:search "API endpoint" --task 002 --from 2026-01-20 --role assistant

# Search all memories in task from specific date
/memory:search --task 001 --from 2026-01-28
```

## Output Format

The search results will be displayed in the following format:

```
=== Search Results ===

Query: "authentication"
Filters: task=001, from=2026-01-20
Found: 5 matches in 3 sessions

--- Session: 2026-01-20-001 (Task: 001) ---
Date: 2026-01-20 14:30:00
Role: assistant
Content: Implemented JWT **authentication** with refresh tokens...
[Context: 150 chars before/after]

--- Session: 2026-01-20-002 (Task: 001) ---
Date: 2026-01-20 16:45:00
Role: user
Content: Can you add **authentication** middleware to the API?
[Context: 150 chars before/after]

...

=== Statistics ===
Total matches: 5
Sessions: 3
Tasks: 1
Date range: 2026-01-20 to 2026-01-20

=== Actions ===
- Load session: /memory:load <session-id>
- Export results: /memory:export --format json
- Refine search: /memory:search <new-query> [filters]
```

## FTS5 Search Syntax

The search supports SQLite FTS5 full-text search syntax:

- **Phrase search**: `"exact phrase"`
- **AND operator**: `term1 AND term2`
- **OR operator**: `term1 OR term2`
- **NOT operator**: `term1 NOT term2`
- **Prefix search**: `auth*` (matches authentication, authorize, etc.)
- **Column search**: `content:authentication` (search in specific column)

Examples:
```bash
# Phrase search
/memory:search "JWT token"

# Boolean operators
/memory:search "authentication AND middleware"
/memory:search "bug OR error"
/memory:search "API NOT deprecated"

# Prefix search
/memory:search auth*

# Combined
/memory:search "auth* AND (JWT OR OAuth)"
```

## Important Notes

- **Performance**: FTS5 provides fast full-text search even with large databases
- **Relevance**: Results are ranked by relevance score
- **Context**: Shows surrounding context for each match
- **Highlighting**: Search terms are highlighted in results
- **Pagination**: Large result sets are paginated automatically

## Error Handling

- If database doesn't exist, suggest running `/memory:save` first
- If no results found, suggest:
  - Broadening search terms
  - Removing filters
  - Checking date range
  - Using wildcard search (auth*)
- If query syntax error, show FTS5 syntax help
- If invalid date format, show correct format (YYYY-MM-DD)

## Integration with Other Commands

After searching, you can:
- **Load session**: `/memory:load <session-id>` to restore context
- **Export results**: `/memory:export --format json` to save results
- **View stats**: `/memory:stats` to see overall statistics
- **Organize**: `/memory:organize` to clean up and categorize

## Success Criteria

- Search executes successfully with provided parameters
- Results are displayed with proper formatting
- Search terms are highlighted in context
- Metadata (task, date, role) is shown for each result
- Result count and statistics are provided
- Suggested actions are offered to user
