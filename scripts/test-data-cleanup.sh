#!/bin/bash

# Memory Manager - Test Data Cleanup Script
# Removes test data from the database

set -e

DB_FILE=".claude/memory/long-term/knowledge.db"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    log_error "Database not found at $DB_FILE"
    exit 1
fi

log_warn "This will delete all test data (tasks starting with 'test-')"
read -p "Are you sure? (y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Cleanup cancelled."
    exit 0
fi

log_info "Cleaning up test data..."

# Delete test data
sqlite3 "$DB_FILE" <<'EOF'
BEGIN TRANSACTION;

-- Delete test memories (will cascade to FTS)
DELETE FROM long_term_memories WHERE task_id LIKE 'test-%';

-- Delete test context history
DELETE FROM context_history WHERE task_id LIKE 'test-%';

-- Delete test compression stats
DELETE FROM compression_stats WHERE task_id LIKE 'test-%';

-- Delete test tasks
DELETE FROM tasks WHERE id LIKE 'test-%';

COMMIT;

-- Optimize database
VACUUM;
ANALYZE;
EOF

if [ $? -eq 0 ]; then
    log_info "Test data cleaned up successfully!"
    log_info "Database optimized."
else
    log_error "Failed to clean up test data!"
    exit 1
fi
