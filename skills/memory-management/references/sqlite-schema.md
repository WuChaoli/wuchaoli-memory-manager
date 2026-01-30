# SQLite Schema and Queries

Complete database schema for the memory-manager plugin's long-term storage.

## Database Location

`.claude/memory/long-term/knowledge.db`

## Schema

### Tables

#### context_history

Stores complete context history before compression.

```sql
CREATE TABLE context_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,
    session_id TEXT NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    content_type TEXT CHECK(content_type IN ('message', 'tool_use', 'tool_result')),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    context_position INTEGER,
    is_compressed BOOLEAN DEFAULT 0,
    compressed_summary TEXT,
    FOREIGN KEY (task_id) REFERENCES tasks(id)
);

CREATE INDEX idx_context_task ON context_history(task_id);
CREATE INDEX idx_context_session ON context_history(session_id);
CREATE INDEX idx_context_role ON context_history(role);
CREATE INDEX idx_context_timestamp ON context_history(timestamp);
```

#### compression_pointers

Stores pointers to compressed content (files, URLs).

```sql
CREATE TABLE compression_pointers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    context_id INTEGER NOT NULL,
    pointer_type TEXT NOT NULL CHECK(pointer_type IN ('file', 'url', 'tool')),
    pointer_value TEXT NOT NULL,
    original_size INTEGER,
    summary TEXT,
    FOREIGN KEY (context_id) REFERENCES context_history(id) ON DELETE CASCADE
);

CREATE INDEX idx_pointer_context ON compression_pointers(context_id);
CREATE INDEX idx_pointer_type ON compression_pointers(pointer_type);
```

#### compression_stats

Tracks compression operations and effectiveness.

```sql
CREATE TABLE compression_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    trigger_reason TEXT CHECK(trigger_reason IN ('>128K', '>60%', 'manual')),
    original_size INTEGER NOT NULL,
    compressed_size INTEGER NOT NULL,
    compression_ratio REAL GENERATED ALWAYS AS (
        CAST(compressed_size AS REAL) / original_size
    ) STORED,
    items_compressed INTEGER DEFAULT 0,
    pointers_created INTEGER DEFAULT 0,
    FOREIGN KEY (task_id) REFERENCES tasks(id)
);

CREATE INDEX idx_stats_task ON compression_stats(task_id);
CREATE INDEX idx_stats_triggered ON compression_stats(triggered_at);
```

#### long_term_memories

Stores extracted knowledge and insights.

```sql
CREATE TABLE long_term_memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT,
    topic TEXT NOT NULL,
    content TEXT NOT NULL,
    summary TEXT,
    importance INTEGER DEFAULT 5 CHECK(importance BETWEEN 1 AND 10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_accessed TIMESTAMP,
    access_count INTEGER DEFAULT 0,
    FOREIGN KEY (task_id) REFERENCES tasks(id)
);

CREATE INDEX idx_memories_topic ON long_term_memories(topic);
CREATE INDEX idx_memories_importance ON long_term_memories(importance);
CREATE INDEX idx_memories_created ON long_term_memories(created_at);
```

#### tasks

Stores task metadata.

```sql
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'active' CHECK(status IN ('active', 'archived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archived_at TIMESTAMP,
    session_count INTEGER DEFAULT 0,
    memory_size INTEGER DEFAULT 0
);

CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_created ON tasks(created_at);
```

#### topics

Categorizes memories by topic.

```sql
CREATE TABLE topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    memory_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_topics_name ON topics(name);
```

### Full-Text Search

#### memories_fts

FTS5 virtual table for fast full-text search.

```sql
CREATE VIRTUAL TABLE memories_fts USING fts5(
    content,
    summary,
    content=long_term_memories,
    content_rowid=id
);

-- Triggers to keep FTS index in sync
CREATE TRIGGER memories_fts_insert AFTER INSERT ON long_term_memories BEGIN
    INSERT INTO memories_fts(rowid, content, summary)
    VALUES (new.id, new.content, new.summary);
END;

CREATE TRIGGER memories_fts_delete AFTER DELETE ON long_term_memories BEGIN
    DELETE FROM memories_fts WHERE rowid = old.id;
END;

CREATE TRIGGER memories_fts_update AFTER UPDATE ON long_term_memories BEGIN
    DELETE FROM memories_fts WHERE rowid = old.id;
    INSERT INTO memories_fts(rowid, content, summary)
    VALUES (new.id, new.content, new.summary);
END;
```

## Common Queries

### Search Queries

#### Full-Text Search

```sql
-- Search all memories
SELECT
    m.id,
    m.topic,
    m.summary,
    m.importance,
    m.created_at,
    rank
FROM long_term_memories m
JOIN memories_fts fts ON m.id = fts.rowid
WHERE memories_fts MATCH ?
ORDER BY rank, m.importance DESC
LIMIT 20;
```

#### Search by Task

```sql
-- Search within specific task
SELECT *
FROM context_history
WHERE task_id = ?
  AND content LIKE ?
ORDER BY timestamp DESC;
```

#### Search by Time Range

```sql
-- Search within date range
SELECT *
FROM long_term_memories
WHERE created_at BETWEEN ? AND ?
  AND content LIKE ?
ORDER BY importance DESC, created_at DESC;
```

#### Search by Role

```sql
-- Search user messages only
SELECT *
FROM context_history
WHERE role = 'user'
  AND content LIKE ?
ORDER BY timestamp DESC;
```

### Statistics Queries

#### Task Statistics

```sql
-- Get task statistics
SELECT
    t.id,
    t.name,
    t.status,
    t.session_count,
    t.memory_size,
    COUNT(DISTINCT ch.session_id) as actual_sessions,
    COUNT(ch.id) as message_count,
    MIN(ch.timestamp) as first_message,
    MAX(ch.timestamp) as last_message
FROM tasks t
LEFT JOIN context_history ch ON t.id = ch.task_id
WHERE t.id = ?
GROUP BY t.id;
```

#### Compression Statistics

```sql
-- Get compression effectiveness
SELECT
    task_id,
    COUNT(*) as compression_count,
    AVG(compression_ratio) as avg_ratio,
    SUM(original_size) as total_original,
    SUM(compressed_size) as total_compressed,
    SUM(pointers_created) as total_pointers
FROM compression_stats
GROUP BY task_id
ORDER BY compression_count DESC;
```

#### Memory Usage

```sql
-- Get memory usage by topic
SELECT
    topic,
    COUNT(*) as memory_count,
    AVG(importance) as avg_importance,
    SUM(LENGTH(content)) as total_size,
    MAX(created_at) as latest_update
FROM long_term_memories
GROUP BY topic
ORDER BY memory_count DESC;
```

### Maintenance Queries

#### Clean Old Compressed Context

```sql
-- Delete compressed context older than 90 days
DELETE FROM context_history
WHERE is_compressed = 1
  AND timestamp < datetime('now', '-90 days');
```

#### Update Access Tracking

```sql
-- Update last accessed time
UPDATE long_term_memories
SET last_accessed = CURRENT_TIMESTAMP,
    access_count = access_count + 1
WHERE id = ?;
```

#### Rebuild FTS Index

```sql
-- Rebuild full-text search index
INSERT INTO memories_fts(memories_fts) VALUES('rebuild');
```

## Initialization Script

```sql
-- Initialize database with all tables
BEGIN TRANSACTION;

-- Create tables in dependency order
CREATE TABLE IF NOT EXISTS tasks (...);
CREATE TABLE IF NOT EXISTS topics (...);
CREATE TABLE IF NOT EXISTS context_history (...);
CREATE TABLE IF NOT EXISTS compression_pointers (...);
CREATE TABLE IF NOT EXISTS compression_stats (...);
CREATE TABLE IF NOT EXISTS long_term_memories (...);

-- Create FTS table and triggers
CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts USING fts5(...);
CREATE TRIGGER IF NOT EXISTS memories_fts_insert ...;
CREATE TRIGGER IF NOT EXISTS memories_fts_delete ...;
CREATE TRIGGER IF NOT EXISTS memories_fts_update ...;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_context_task ...;
-- ... (all other indexes)

COMMIT;
```

## Performance Considerations

### Indexing Strategy

- Index foreign keys for JOIN performance
- Index timestamp columns for time-range queries
- Index role column for role-based filtering
- Use FTS5 for full-text search (much faster than LIKE)

### Query Optimization

- Use prepared statements to prevent SQL injection
- Limit result sets with LIMIT clause
- Use covering indexes when possible
- Analyze query plans with EXPLAIN QUERY PLAN

### Maintenance

- Vacuum database periodically: `VACUUM;`
- Analyze statistics: `ANALYZE;`
- Rebuild FTS index if search is slow
- Archive old compressed context

## Backup and Recovery

### Backup

```bash
# Backup database
sqlite3 .claude/memory/long-term/knowledge.db ".backup backup.db"

# Export to SQL
sqlite3 .claude/memory/long-term/knowledge.db ".dump" > backup.sql
```

### Recovery

```bash
# Restore from backup
cp backup.db .claude/memory/long-term/knowledge.db

# Restore from SQL
sqlite3 .claude/memory/long-term/knowledge.db < backup.sql
```

### Integrity Check

```sql
-- Check database integrity
PRAGMA integrity_check;

-- Check foreign key constraints
PRAGMA foreign_key_check;
```
