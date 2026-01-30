#!/bin/bash

# Memory Manager - Task Export Script
# Export task data to various formats (JSON, Markdown, CSV)

set -e  # Exit on error

# Configuration
DB_DIR=".claude/memory/long-term"
DB_FILE="$DB_DIR/knowledge.db"
EXPORT_DIR=".claude/memory/exports"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] <task-id>

Export task data to various formats

OPTIONS:
    -f, --format FORMAT    Output format: json, markdown, csv (default: json)
    -o, --output FILE      Output file path (default: auto-generated)
    -a, --all              Export all tasks
    -s, --sessions         Include all session details
    -c, --compress         Compress output (gzip)
    -h, --help             Show this help message

EXAMPLES:
    # Export task to JSON
    $0 task-001

    # Export to Markdown
    $0 -f markdown task-001

    # Export with custom output path
    $0 -o exports/my-task.json task-001

    # Export all tasks
    $0 --all

    # Export with session details and compression
    $0 -s -c task-001

EOF
    exit 0
}

# Check dependencies
check_dependencies() {
    if ! command -v sqlite3 &> /dev/null; then
        log_error "sqlite3 is not installed. Please install it first."
        exit 1
    fi

    if [ ! -f "$DB_FILE" ]; then
        log_error "Database not found at $DB_FILE"
        log_error "Run 'scripts/init-db.sh' to initialize the database."
        exit 1
    fi
}

# Export task to JSON
export_json() {
    local task_id="$1"
    local output_file="$2"
    local include_sessions="$3"

    log_step "Exporting task $task_id to JSON..."

    # Check if task exists
    local task_exists=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM tasks WHERE id = '$task_id';")
    if [ "$task_exists" = "0" ]; then
        log_error "Task $task_id not found"
        exit 1
    fi

    # Use Python to build proper JSON
    python3 - "$task_id" << 'PYTHON_SCRIPT' > "$output_file"
import sqlite3
import json
import sys
from datetime import datetime

db_file = ".claude/memory/long-term/knowledge.db"
task_id = sys.argv[1] if len(sys.argv) > 1 else None

if not task_id:
    print("{\"error\": \"Task ID not provided\"}", file=sys.stderr)
    sys.exit(1)

conn = sqlite3.connect(db_file)
conn.row_factory = sqlite3.Row

# Get task metadata
cursor = conn.cursor()
cursor.execute("SELECT * FROM tasks WHERE id = ?", (task_id,))
task_row = cursor.fetchone()
task_data = dict(task_row) if task_row else {}

# Get context history
cursor.execute("""
    SELECT id, session_id, role, content, content_type, timestamp, context_position
    FROM context_history
    WHERE task_id = ?
    ORDER BY timestamp
""", (task_id,))
context_data = [dict(row) for row in cursor.fetchall()]

# Get long-term memories
cursor.execute("""
    SELECT id, topic, summary, importance, created_at, access_count
    FROM long_term_memories
    WHERE task_id = ?
    ORDER BY importance DESC, created_at DESC
""", (task_id,))
memories_data = [dict(row) for row in cursor.fetchall()]

# Get compression stats
cursor.execute("""
    SELECT * FROM compression_stats
    WHERE task_id = ?
    ORDER BY triggered_at DESC
""", (task_id,))
compression_data = [dict(row) for row in cursor.fetchall()]

conn.close()

# Build final JSON
output = {
    "task": task_data,
    "context_history": context_data,
    "memories": memories_data,
    "compression_stats": compression_data,
    "export_metadata": {
        "exported_at": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
        "format": "json",
        "version": "1.0"
    }
}

print(json.dumps(output, indent=2, ensure_ascii=False, default=str))
PYTHON_SCRIPT

    if [ $? -eq 0 ]; then
        log_info "Exported to: $output_file"
        log_info "File size: $(du -h "$output_file" | cut -f1)"
    else
        log_error "Export failed"
        exit 1
    fi
}

# Export task to Markdown
export_markdown() {
    local task_id="$1"
    local output_file="$2"

    log_step "Exporting task $task_id to Markdown..."

    # Get task info
    local task_name=$(sqlite3 "$DB_FILE" "SELECT name FROM tasks WHERE id = '$task_id';")
    local task_desc=$(sqlite3 "$DB_FILE" "SELECT description FROM tasks WHERE id = '$task_id';")
    local task_status=$(sqlite3 "$DB_FILE" "SELECT status FROM tasks WHERE id = '$task_id';")
    local created_at=$(sqlite3 "$DB_FILE" "SELECT created_at FROM tasks WHERE id = '$task_id';")
    local session_count=$(sqlite3 "$DB_FILE" "SELECT session_count FROM tasks WHERE id = '$task_id';")

    if [ -z "$task_name" ]; then
        log_error "Task $task_id not found"
        exit 1
    fi

    # Create markdown file
    cat > "$output_file" << EOF
# Task Export: $task_name

**Task ID**: $task_id
**Status**: $task_status
**Created**: $created_at
**Sessions**: $session_count

## Description

$task_desc

## Statistics

EOF

    # Add statistics
    sqlite3 "$DB_FILE" << SQL >> "$output_file"
.mode markdown
SELECT
    'Total Messages' as Metric,
    COUNT(*) as Value
FROM context_history
WHERE task_id = '$task_id'
UNION ALL
SELECT
    'Total Memories',
    COUNT(*)
FROM long_term_memories
WHERE task_id = '$task_id'
UNION ALL
SELECT
    'Compression Events',
    COUNT(*)
FROM compression_stats
WHERE task_id = '$task_id';
SQL

    # Add memories section
    cat >> "$output_file" << EOF

## Long-Term Memories

EOF

    sqlite3 "$DB_FILE" << SQL >> "$output_file"
.mode markdown
SELECT
    topic as Topic,
    summary as Summary,
    importance as Importance,
    created_at as Created
FROM long_term_memories
WHERE task_id = '$task_id'
ORDER BY importance DESC, created_at DESC
LIMIT 50;
SQL

    # Add compression stats
    cat >> "$output_file" << EOF

## Compression Statistics

EOF

    sqlite3 "$DB_FILE" << SQL >> "$output_file"
.mode markdown
SELECT
    triggered_at as Time,
    trigger_reason as Reason,
    original_size as Original,
    compressed_size as Compressed,
    ROUND(compression_ratio * 100, 1) || '%' as Ratio,
    items_compressed as Items
FROM compression_stats
WHERE task_id = '$task_id'
ORDER BY triggered_at DESC;
SQL

    # Add export metadata
    cat >> "$output_file" << EOF

---

**Exported**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Format**: Markdown
**Version**: 1.0

EOF

    log_info "Exported to: $output_file"
    log_info "File size: $(du -h "$output_file" | cut -f1)"
}

# Export task to CSV
export_csv() {
    local task_id="$1"
    local output_file="$2"

    log_step "Exporting task $task_id to CSV..."

    # Export context history to CSV
    sqlite3 "$DB_FILE" << SQL > "$output_file"
.mode csv
.headers on
SELECT
    id,
    task_id,
    session_id,
    role,
    SUBSTR(content, 1, 100) as content_preview,
    content_type,
    timestamp,
    context_position,
    is_compressed
FROM context_history
WHERE task_id = '$task_id'
ORDER BY timestamp;
SQL

    if [ $? -eq 0 ]; then
        log_info "Exported to: $output_file"
        log_info "File size: $(du -h "$output_file" | cut -f1)"
        log_info "Records: $(wc -l < "$output_file")"
    else
        log_error "Export failed"
        exit 1
    fi
}

# Export all tasks
export_all_tasks() {
    local format="$1"
    local output_dir="$EXPORT_DIR/all-tasks-$(date +%Y%m%d-%H%M%S)"

    log_step "Exporting all tasks..."

    mkdir -p "$output_dir"

    # Get all task IDs
    local task_ids=$(sqlite3 "$DB_FILE" "SELECT id FROM tasks;")

    local count=0
    for task_id in $task_ids; do
        local output_file="$output_dir/$task_id.$format"

        case "$format" in
            json)
                export_json "$task_id" "$output_file" "false"
                ;;
            markdown|md)
                export_markdown "$task_id" "$output_file"
                ;;
            csv)
                export_csv "$task_id" "$output_file"
                ;;
        esac

        ((count++))
    done

    log_info "Exported $count tasks to: $output_dir"
}

# Compress output file
compress_file() {
    local file="$1"

    log_step "Compressing output..."

    if command -v gzip &> /dev/null; then
        gzip -f "$file"
        log_info "Compressed: ${file}.gz"
    else
        log_warn "gzip not found, skipping compression"
    fi
}

# Main script
main() {
    # Default values
    local format="json"
    local output_file=""
    local task_id=""
    local export_all=false
    local include_sessions=false
    local compress=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--format)
                format="$2"
                shift 2
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -a|--all)
                export_all=true
                shift
                ;;
            -s|--sessions)
                include_sessions=true
                shift
                ;;
            -c|--compress)
                compress=true
                shift
                ;;
            -h|--help)
                show_usage
                ;;
            *)
                task_id="$1"
                shift
                ;;
        esac
    done

    # Validate format
    case "$format" in
        json|markdown|md|csv)
            ;;
        *)
            log_error "Invalid format: $format"
            log_error "Supported formats: json, markdown, csv"
            exit 1
            ;;
    esac

    # Check dependencies
    check_dependencies

    # Create export directory
    mkdir -p "$EXPORT_DIR"

    # Export all tasks or single task
    if [ "$export_all" = true ]; then
        export_all_tasks "$format"
    else
        # Validate task ID
        if [ -z "$task_id" ]; then
            log_error "Task ID is required"
            show_usage
        fi

        # Generate output filename if not provided
        if [ -z "$output_file" ]; then
            output_file="$EXPORT_DIR/${task_id}-$(date +%Y%m%d-%H%M%S).$format"
        fi

        # Export based on format
        case "$format" in
            json)
                export_json "$task_id" "$output_file" "$include_sessions"
                ;;
            markdown|md)
                export_markdown "$task_id" "$output_file"
                ;;
            csv)
                export_csv "$task_id" "$output_file"
                ;;
        esac

        # Compress if requested
        if [ "$compress" = true ]; then
            compress_file "$output_file"
        fi
    fi

    log_info "Export completed successfully!"
}

# Run main function
main "$@"
