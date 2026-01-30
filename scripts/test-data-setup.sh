#!/bin/bash

# Memory Manager - Test Data Setup Script
# Creates test data for testing the Memory Manager plugin

set -e  # Exit on error

DB_FILE=".claude/memory/long-term/knowledge.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    log_warn "Database not found. Running init-db.sh first..."
    ./scripts/init-db.sh
fi

log_step "Creating test data..."

# Insert test data
sqlite3 "$DB_FILE" <<'EOF'
BEGIN TRANSACTION;

-- Insert test tasks
INSERT OR REPLACE INTO tasks (id, name, description, status, created_at, session_count, memory_size) VALUES
  ('test-001', 'Authentication Feature', 'Implement JWT authentication with refresh tokens', 'active', '2026-01-25 10:00:00', 3, 45000),
  ('test-002', 'API Development', 'Build REST API endpoints for user management', 'active', '2026-01-26 14:00:00', 2, 32000),
  ('test-003', 'Database Migration', 'Migrate from SQLite to PostgreSQL', 'archived', '2026-01-20 09:00:00', 5, 78000);

-- Insert test memories
INSERT OR REPLACE INTO long_term_memories (task_id, topic, content, summary, importance, created_at, access_count) VALUES
  ('test-001', 'implementation', 'Implemented JWT authentication using HS256 algorithm. Created auth middleware for Express.js. Tokens expire after 15 minutes with refresh token support.', 'JWT auth with HS256 and refresh tokens', 9, '2026-01-25 11:30:00', 5),
  ('test-001', 'testing', 'Added comprehensive unit tests for authentication endpoints. Tests cover token generation, validation, refresh, and expiration scenarios.', 'Auth endpoint tests complete', 7, '2026-01-25 15:00:00', 3),
  ('test-001', 'security', 'Implemented secure token refresh mechanism. Refresh tokens stored in httpOnly cookies. Added rate limiting for auth endpoints.', 'Secure token refresh implemented', 8, '2026-01-25 16:30:00', 4),
  ('test-001', 'documentation', 'Documented authentication flow and API endpoints. Created Postman collection for testing.', 'Auth documentation complete', 6, '2026-01-25 17:00:00', 2),
  ('test-002', 'architecture', 'Designed RESTful API structure following best practices. Implemented layered architecture with controllers, services, and repositories.', 'RESTful API architecture designed', 8, '2026-01-26 15:00:00', 4),
  ('test-002', 'implementation', 'Implemented CRUD endpoints for user management. Added input validation and error handling.', 'User CRUD endpoints complete', 7, '2026-01-26 17:30:00', 3),
  ('test-002', 'testing', 'Created integration tests for API endpoints. Achieved 85% code coverage.', 'API integration tests done', 7, '2026-01-27 10:00:00', 2),
  ('test-003', 'planning', 'Evaluated PostgreSQL vs MySQL for migration. Decided on PostgreSQL for better JSON support and performance.', 'Database evaluation complete', 6, '2026-01-20 10:00:00', 1),
  ('test-003', 'implementation', 'Completed database migration to PostgreSQL. Migrated all tables and data successfully.', 'PostgreSQL migration complete', 8, '2026-01-22 16:00:00', 2),
  ('test-003', 'lessons', 'Learned about PostgreSQL-specific features and optimization techniques. Documented migration process for future reference.', 'Migration lessons documented', 7, '2026-01-23 11:00:00', 1);

-- Insert test context history
INSERT OR REPLACE INTO context_history (task_id, session_id, role, content, content_type, timestamp, context_position) VALUES
  ('test-001', '2026-01-25-001', 'user', 'I need to implement JWT authentication for our API', 'message', '2026-01-25 10:00:00', 1),
  ('test-001', '2026-01-25-001', 'assistant', 'I will help you implement JWT authentication. Let me start by creating the auth module.', 'message', '2026-01-25 10:01:00', 2),
  ('test-001', '2026-01-25-001', 'tool', 'Created file: src/auth/jwt.js', 'tool_result', '2026-01-25 10:05:00', 3),
  ('test-001', '2026-01-25-002', 'user', 'Can you add refresh token support?', 'message', '2026-01-25 14:00:00', 1),
  ('test-001', '2026-01-25-002', 'assistant', 'Yes, I will add refresh token functionality.', 'message', '2026-01-25 14:01:00', 2),
  ('test-002', '2026-01-26-001', 'user', 'Let us build the user management API', 'message', '2026-01-26 14:00:00', 1),
  ('test-002', '2026-01-26-001', 'assistant', 'I will create RESTful endpoints for user CRUD operations.', 'message', '2026-01-26 14:01:00', 2);

-- Insert compression statistics
INSERT OR REPLACE INTO compression_stats (task_id, triggered_at, trigger_reason, original_size, compressed_size, items_compressed, pointers_created, execution_time_ms) VALUES
  ('test-001', '2026-01-25 12:00:00', '>60%', 150000, 60000, 15, 8, 1250),
  ('test-001', '2026-01-25 16:00:00', '>128K', 180000, 72000, 20, 12, 1500),
  ('test-002', '2026-01-26 16:00:00', '>60%', 120000, 48000, 12, 6, 980);

COMMIT;
EOF

if [ $? -eq 0 ]; then
    log_info "Test data created successfully!"

    # Show statistics
    log_step "Test data statistics:"

    TASK_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM tasks WHERE id LIKE 'test-%';")
    echo "  Tasks: $TASK_COUNT"

    MEMORY_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM long_term_memories WHERE task_id LIKE 'test-%';")
    echo "  Memories: $MEMORY_COUNT"

    CONTEXT_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM context_history WHERE task_id LIKE 'test-%';")
    echo "  Context entries: $CONTEXT_COUNT"

    COMPRESSION_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM compression_stats WHERE task_id LIKE 'test-%';")
    echo "  Compression events: $COMPRESSION_COUNT"

    echo ""
    log_info "You can now run tests using this data."
    log_info "To clean up test data, run: ./scripts/test-data-cleanup.sh"
else
    log_warn "Failed to create test data!"
    exit 1
fi
