#!/usr/bin/env python3
"""
Memory Manager - Query Tool
Query and analyze memories from the SQLite database
"""

import sqlite3
import argparse
import json
import sys
from datetime import datetime
from pathlib import Path

# Database configuration
DB_PATH = Path(".claude/memory/long-term/knowledge.db")

class MemoryQuery:
    def __init__(self, db_path=DB_PATH):
        self.db_path = db_path
        self.conn = None

    def connect(self):
        """Connect to database"""
        if not self.db_path.exists():
            print(f"Error: Database not found at {self.db_path}", file=sys.stderr)
            print("Run 'scripts/init-db.sh' to initialize the database.", file=sys.stderr)
            sys.exit(1)

        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row  # Access columns by name
        return self

    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()

    def __enter__(self):
        return self.connect()

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()

    def search_full_text(self, query, limit=20):
        """Full-text search across all memories"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT
                m.id,
                m.topic,
                m.summary,
                m.importance,
                m.created_at,
                m.access_count,
                fts.rank
            FROM long_term_memories m
            JOIN memories_fts fts ON m.id = fts.rowid
            WHERE memories_fts MATCH ?
            ORDER BY fts.rank, m.importance DESC
            LIMIT ?
        """, (query, limit))

        return [dict(row) for row in cursor.fetchall()]

    def search_by_task(self, task_id, query=None, limit=50):
        """Search within specific task"""
        cursor = self.conn.cursor()

        if query:
            cursor.execute("""
                SELECT *
                FROM context_history
                WHERE task_id = ?
                  AND content LIKE ?
                ORDER BY timestamp DESC
                LIMIT ?
            """, (task_id, f"%{query}%", limit))
        else:
            cursor.execute("""
                SELECT *
                FROM context_history
                WHERE task_id = ?
                ORDER BY timestamp DESC
                LIMIT ?
            """, (task_id, limit))

        return [dict(row) for row in cursor.fetchall()]

    def search_by_time_range(self, start_date, end_date, query=None):
        """Search within date range"""
        cursor = self.conn.cursor()

        if query:
            cursor.execute("""
                SELECT *
                FROM long_term_memories
                WHERE created_at BETWEEN ? AND ?
                  AND content LIKE ?
                ORDER BY importance DESC, created_at DESC
            """, (start_date, end_date, f"%{query}%"))
        else:
            cursor.execute("""
                SELECT *
                FROM long_term_memories
                WHERE created_at BETWEEN ? AND ?
                ORDER BY importance DESC, created_at DESC
            """, (start_date, end_date))

        return [dict(row) for row in cursor.fetchall()]

    def search_by_role(self, role, query=None, limit=50):
        """Search by message role"""
        cursor = self.conn.cursor()

        if query:
            cursor.execute("""
                SELECT *
                FROM context_history
                WHERE role = ?
                  AND content LIKE ?
                ORDER BY timestamp DESC
                LIMIT ?
            """, (role, f"%{query}%", limit))
        else:
            cursor.execute("""
                SELECT *
                FROM context_history
                WHERE role = ?
                ORDER BY timestamp DESC
                LIMIT ?
            """, (role, limit))

        return [dict(row) for row in cursor.fetchall()]

    def get_task_stats(self, task_id=None):
        """Get task statistics"""
        cursor = self.conn.cursor()

        if task_id:
            cursor.execute("""
                SELECT * FROM v_active_tasks WHERE id = ?
            """, (task_id,))
            return dict(cursor.fetchone() or {})
        else:
            cursor.execute("SELECT * FROM v_active_tasks")
            return [dict(row) for row in cursor.fetchall()]

    def get_compression_stats(self, task_id=None):
        """Get compression statistics"""
        cursor = self.conn.cursor()

        if task_id:
            cursor.execute("""
                SELECT * FROM v_compression_stats WHERE task_id = ?
            """, (task_id,))
            return dict(cursor.fetchone() or {})
        else:
            cursor.execute("SELECT * FROM v_compression_stats")
            return [dict(row) for row in cursor.fetchall()]

    def get_memory_by_topic(self):
        """Get memory usage by topic"""
        cursor = self.conn.cursor()
        cursor.execute("SELECT * FROM v_memory_by_topic")
        return [dict(row) for row in cursor.fetchall()]

    def get_recent_memories(self, limit=10):
        """Get most recent memories"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT *
            FROM long_term_memories
            ORDER BY created_at DESC
            LIMIT ?
        """, (limit,))
        return [dict(row) for row in cursor.fetchall()]

    def get_important_memories(self, min_importance=7, limit=20):
        """Get high-importance memories"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT *
            FROM long_term_memories
            WHERE importance >= ?
            ORDER BY importance DESC, created_at DESC
            LIMIT ?
        """, (min_importance, limit))
        return [dict(row) for row in cursor.fetchall()]

    def get_memory_detail(self, memory_id):
        """Get full memory content"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT *
            FROM long_term_memories
            WHERE id = ?
        """, (memory_id,))
        return dict(cursor.fetchone() or {})


def format_output(data, format_type='json'):
    """Format output data"""
    if format_type == 'json':
        return json.dumps(data, indent=2, ensure_ascii=False, default=str)
    elif format_type == 'table':
        if not data:
            return "No results found."

        if isinstance(data, dict):
            data = [data]

        # Simple table format
        keys = data[0].keys()
        lines = []
        lines.append(" | ".join(str(k) for k in keys))
        lines.append("-" * (len(lines[0]) + len(keys) * 3))

        for row in data:
            values = [str(row.get(k, ''))[:50] for k in keys]  # Truncate long values
            lines.append(" | ".join(values))

        return "\n".join(lines)
    else:
        return str(data)


def main():
    parser = argparse.ArgumentParser(
        description="Query memories from Memory Manager database",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Full-text search
  %(prog)s search "JWT authentication"

  # Search within task
  %(prog)s --task task-001 search "bug fix"

  # Search by time range
  %(prog)s --from 2026-01-20 --to 2026-01-29 search "API"

  # Search user messages
  %(prog)s --role user search "how to"

  # Get task statistics
  %(prog)s stats --task task-001

  # Get compression stats
  %(prog)s compression

  # Get recent memories
  %(prog)s recent --limit 20

  # Get important memories
  %(prog)s important --min-importance 8
        """
    )

    parser.add_argument('command', choices=[
        'search', 'stats', 'compression', 'topics', 'recent', 'important', 'detail'
    ], help='Command to execute')

    parser.add_argument('query', nargs='?', help='Search query')
    parser.add_argument('--task', help='Task ID to filter by')
    parser.add_argument('--from', dest='start_date', help='Start date (YYYY-MM-DD)')
    parser.add_argument('--to', dest='end_date', help='End date (YYYY-MM-DD)')
    parser.add_argument('--role', choices=['user', 'assistant', 'system', 'tool'],
                       help='Message role to filter by')
    parser.add_argument('--limit', type=int, default=20, help='Maximum results')
    parser.add_argument('--min-importance', type=int, default=7,
                       help='Minimum importance level (1-10)')
    parser.add_argument('--format', choices=['json', 'table'], default='json',
                       help='Output format')
    parser.add_argument('--id', type=int, help='Memory ID for detail command')

    args = parser.parse_args()

    try:
        with MemoryQuery() as mq:
            result = None

            if args.command == 'search':
                if not args.query:
                    parser.error("search command requires a query")

                if args.task:
                    result = mq.search_by_task(args.task, args.query, args.limit)
                elif args.start_date and args.end_date:
                    result = mq.search_by_time_range(args.start_date, args.end_date, args.query)
                elif args.role:
                    result = mq.search_by_role(args.role, args.query, args.limit)
                else:
                    result = mq.search_full_text(args.query, args.limit)

            elif args.command == 'stats':
                result = mq.get_task_stats(args.task)

            elif args.command == 'compression':
                result = mq.get_compression_stats(args.task)

            elif args.command == 'topics':
                result = mq.get_memory_by_topic()

            elif args.command == 'recent':
                result = mq.get_recent_memories(args.limit)

            elif args.command == 'important':
                result = mq.get_important_memories(args.min_importance, args.limit)

            elif args.command == 'detail':
                if not args.id:
                    parser.error("detail command requires --id")
                result = mq.get_memory_detail(args.id)

            # Output result
            print(format_output(result, args.format))

    except sqlite3.Error as e:
        print(f"Database error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
