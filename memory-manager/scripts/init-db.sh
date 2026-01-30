#!/bin/bash

# Memory Manager - Database Initialization Script
# Creates SQLite database with complete schema for memory management

set -e  # Exit on error

# Configuration
DB_DIR=".claude/memory/long-term"
DB_FILE="$DB_DIR/knowledge.db"
BACKUP_DIR="$DB_DIR/backups"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Check if sqlite3 is installed
if ! command -v sqlite3 &> /dev/null; then
    log_error "sqlite3 is not installed. Please install it first."
    exit 1
fi

# Create directory structure
log_info "Creating directory structure..."
mkdir -p "$DB_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p ".claude/memory/active-tasks"
mkdir -p ".claude/memory/archived-tasks"

# Backup existing database if it exists
if [ -f "$DB_FILE" ]; then
    BACKUP_FILE="$BACKUP_DIR/knowledge_$(date +%Y%m%d_%H%M%S).db"
    log_warn "Database already exists. Creating backup: $BACKUP_FILE"
    cp "$DB_FILE" "$BACKUP_FILE"
fi

# Create database and schema
log_info "Initializing database: $DB_FILE"

sqlite3 "$DB_FILE" <<'EOF'
-- Enable foreign keys
PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- ============================================================================
-- Core Tables
-- ============================================================================

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'active' CHECK(status IN ('active', 'archived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archived_at TIMESTAMP,
    session_count INTEGER DEFAULT 0,
    memory_size INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_created ON tasks(created_at);

-- Topics table
CREATE TABLE IF NOT EXISTS topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    memory_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_topics_name ON topics(name);

-- Context history table
CREATE TABLE IF NOT EXISTS context_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,
    session_id TEXT NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('user', 'assistant', 'system', 'tool')),
    content TEXT NOT NULL,
    content_type TEXT CHECK(content_type IN ('message', 'tool_use', 'tool_result')),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    context_position INTEGER,
    is_compressed BOOLEAN DEFAULT 0,
    compressed_summary TEXT,
    FOREIGN KEY (task_id) REFERENCES tasks(id)
);

CREATE INDEX IF NOT EXISTS idx_context_task ON context_history(task_id);
CREATE INDEX IF NOT EXISTS idx_context_session ON context_history(session_id);
CREATE INDEX IF NOT EXISTS idx_context_role ON context_history(role);
CREATE INDEX IF NOT EXISTS idx_context_timestamp ON context_history(timestamp);

-- Compression pointers table
CREATE TABLE IF NOT EXISTS compression_pointers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    context_id INTEGER NOT NULL,
    pointer_type TEXT NOT NULL CHECK(pointer_type IN ('file', 'url', 'tool', 'conversation')),
    pointer_value TEXT NOT NULL,
    original_size INTEGER,
    compressed_size INTEGER,
    content_hash TEXT,
    summary TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (context_id) REFERENCES context_history(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_pointer_context ON compression_pointers(context_id);
CREATE INDEX IF NOT EXISTS idx_pointer_type ON compression_pointers(pointer_type);
CREATE INDEX IF NOT EXISTS idx_pointer_hash ON compression_pointers(content_hash);

-- Compression statistics table
CREATE TABLE IF NOT EXISTS compression_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    trigger_reason TEXT CHECK(trigger_reason IN ('>128K', '>60%', 'manual', 'auto')),
    original_size INTEGER NOT NULL,
    compressed_size INTEGER NOT NULL,
    compression_ratio REAL GENERATED ALWAYS AS (
        CAST(compressed_size AS REAL) / NULLIF(original_size, 0)
    ) STORED,
    items_compressed INTEGER DEFAULT 0,
    pointers_created INTEGER DEFAULT 0,
    execution_time_ms INTEGER,
    FOREIGN KEY (task_id) REFERENCES tasks(id)
);

CREATE INDEX IF NOT EXISTS idx_stats_task ON compression_stats(task_id);
CREATE INDEX IF NOT EXISTS idx_stats_triggered ON compression_stats(triggered_at);

-- Long-term memories table
CREATE TABLE IF NOT EXISTS long_term_memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT,
    topic TEXT NOT NULL,
    content TEXT NOT NULL,
    summary TEXT,
    importance INTEGER DEFAULT 5 CHECK(importance BETWEEN 1 AND 10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_accessed TIMESTAMP,
    access_count INTEGER DEFAULT 0,
    FOREIGN KEY (task_id) REFERENCES tasks(id),
    FOREIGN KEY (topic) REFERENCES topics(name)
);

CREATE INDEX IF NOT EXISTS idx_memories_topic ON long_term_memories(topic);
CREATE INDEX IF NOT EXISTS idx_memories_importance ON long_term_memories(importance);
CREATE INDEX IF NOT EXISTS idx_memories_created ON long_term_memories(created_at);
CREATE INDEX IF NOT EXISTS idx_memories_task ON long_term_memories(task_id);

-- ============================================================================
-- Full-Text Search
-- ============================================================================

-- FTS5 virtual table for memories
CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts USING fts5(
    content,
    summary,
    content=long_term_memories,
    content_rowid=id,
    tokenize='porter unicode61'
);

-- Triggers to keep FTS index in sync
CREATE TRIGGER IF NOT EXISTS memories_fts_insert AFTER INSERT ON long_term_memories BEGIN
    INSERT INTO memories_fts(rowid, content, summary)
    VALUES (new.id, new.content, new.summary);
END;

CREATE TRIGGER IF NOT EXISTS memories_fts_delete AFTER DELETE ON long_term_memories BEGIN
    DELETE FROM memories_fts WHERE rowid = old.id;
END;

CREATE TRIGGER IF NOT EXISTS memories_fts_update AFTER UPDATE ON long_term_memories BEGIN
    DELETE FROM memories_fts WHERE rowid = old.id;
    INSERT INTO memories_fts(rowid, content, summary)
    VALUES (new.id, new.content, new.summary);
END;

-- ============================================================================
-- Views for Common Queries
-- ============================================================================

-- Active tasks view
CREATE VIEW IF NOT EXISTS v_active_tasks AS
SELECT
    t.*,
    COUNT(DISTINCT ch.session_id) as actual_sessions,
    COUNT(ch.id) as message_count,
    MIN(ch.timestamp) as first_message,
    MAX(ch.timestamp) as last_message
FROM tasks t
LEFT JOIN context_history ch ON t.id = ch.task_id
WHERE t.status = 'active'
GROUP BY t.id;

-- Compression effectiveness view
CREATE VIEW IF NOT EXISTS v_compression_stats AS
SELECT
    task_id,
    COUNT(*) as compression_count,
    AVG(compression_ratio) as avg_ratio,
    SUM(original_size) as total_original,
    SUM(compressed_size) as total_compressed,
    SUM(original_size - compressed_size) as total_saved,
    SUM(pointers_created) as total_pointers,
    AVG(execution_time_ms) as avg_execution_time
FROM compression_stats
GROUP BY task_id;

-- Memory usage by topic view
CREATE VIEW IF NOT EXISTS v_memory_by_topic AS
SELECT
    topic,
    COUNT(*) as memory_count,
    AVG(importance) as avg_importance,
    SUM(LENGTH(content)) as total_size,
    MAX(created_at) as latest_update,
    SUM(access_count) as total_accesses
FROM long_term_memories
GROUP BY topic
ORDER BY memory_count DESC;

COMMIT;

-- ============================================================================
-- Initial Data
-- ============================================================================

-- Insert default topics
INSERT OR IGNORE INTO topics (name, description) VALUES
    ('architecture', 'System architecture and design decisions'),
    ('implementation', 'Code implementation details and patterns'),
    ('debugging', 'Bug fixes and troubleshooting solutions'),
    ('testing', 'Test strategies and test cases'),
    ('performance', 'Performance optimization insights'),
    ('security', 'Security considerations and implementations'),
    ('documentation', 'Documentation and knowledge sharing'),
    ('tools', 'Tool usage and configurations'),
    ('workflow', 'Development workflow and processes'),
    ('lessons', 'Lessons learned and best practices');

-- Optimize database
ANALYZE;

EOF

# Verify database creation
if [ $? -eq 0 ]; then
    log_info "Database initialized successfully!"

    # Show database info
    log_info "Database location: $DB_FILE"
    log_info "Database size: $(du -h "$DB_FILE" | cut -f1)"

    # Show table count
    TABLE_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sqlite_master WHERE type='table';")
    log_info "Tables created: $TABLE_COUNT"

    # Show view count
    VIEW_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sqlite_master WHERE type='view';")
    log_info "Views created: $VIEW_COUNT"

    # Show index count
    INDEX_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sqlite_master WHERE type='index';")
    log_info "Indexes created: $INDEX_COUNT"

    # Verify FTS table
    FTS_EXISTS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='memories_fts';")
    if [ "$FTS_EXISTS" -eq 1 ]; then
        log_info "Full-text search (FTS5) enabled ✓"
    else
        log_warn "Full-text search table not found"
    fi

    # Run integrity check
    log_info "Running integrity check..."
    INTEGRITY=$(sqlite3 "$DB_FILE" "PRAGMA integrity_check;")
    if [ "$INTEGRITY" = "ok" ]; then
        log_info "Database integrity check: OK ✓"
    else
        log_error "Database integrity check failed: $INTEGRITY"
        exit 1
    fi

    echo ""
    log_info "Memory Manager database is ready to use!"
    log_info "You can now use /memory:* commands to manage your memories."

else
    log_error "Database initialization failed!"
    exit 1
fi
