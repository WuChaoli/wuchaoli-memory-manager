---
name: Compact Strategy
description: This skill should be used when the user asks to "compact context", "trigger compression", "reduce memory usage", "handle context overflow", or mentions compact operations, compression strategies, or context management. Provides comprehensive guidance for executing context compaction with the 30%-70% algorithm.
version: 0.1.0
---

# Compact Strategy

## Overview

Compact strategy provides intelligent context compression to prevent context overflow while preserving essential information. This skill guides the execution of the 30%-70% compression algorithm, ensuring optimal context usage and seamless recovery capabilities.

## When to Compact

### Automatic Triggers

**Context Thresholds**:
- **Warning Level** (60% / 120K tokens): Prepare for compression
- **Action Level** (70% / 140K tokens): Recommend compression
- **Critical Level** (80% / 160K tokens): Force compression
- **Emergency Level** (90% / 180K tokens): Aggressive compression

**PreCompact Hook**:
Automatically triggers when:
```python
if context_tokens > 128000 or context_percentage > 0.60:
    trigger_precompact_hook()
```

### Manual Triggers

**User Commands**:
- `/memory:compact` - Manual compression
- `/memory:analyze` - Check if compression needed
- `/memory:stats` - View context status

**Good Times to Compact**:
- After completing a subtask
- Before starting major new work
- After loading many files
- When context feels "heavy"

**Bad Times to Compact**:
- During active debugging
- While referencing multiple files
- In middle of complex reasoning
- When actively using historical context

## 30%-70% Algorithm

### Core Concept

**Principle**: Preserve recent context, compress historical content

```
Original Context: 150K tokens (100%)
├── Recent 30% (45K) → Keep intact → 45K tokens
└── Older 70% (105K) → Compress to 30% → 31.5K tokens
Result: 76.5K tokens (51% of original)
```

### Partitioning Strategy

**Preservation Zone** (Recent 30%):
- Last 10-20 messages
- Current file contents being edited
- Active tool results (last 5-10 minutes)
- Recent decisions and rationale
- Current task context

**Compression Zone** (Older 70%):
- Historical conversations (>20 messages old)
- Old file contents (not recently modified)
- Completed subtask discussions
- Verbose command outputs
- Repeated tool results

### Compression Targets

**High Priority** (Compress first):
1. Large file contents (>5K tokens)
2. Verbose command outputs (>2K tokens)
3. Repeated file reads
4. Old search results
5. Historical conversations (>1 hour old)

**Medium Priority** (Compress if needed):
1. Moderate file contents (1-5K tokens)
2. Standard command outputs
3. Tool results
4. Older conversations (30min - 1 hour)

**Low Priority** (Keep if possible):
1. Small file contents (<1K tokens)
2. Recent conversations (<30 min)
3. Key decisions and rationale
4. Error messages and solutions

## Compression Execution

### Pre-Compression Steps

1. **Analyze Current Context**:
   ```python
   analysis = analyze_context()
   # Returns: token distribution, compression opportunities, savings estimate
   ```

2. **Save Full Context**:
   ```python
   context_id = save_to_sqlite(current_context)
   # Store complete context before any modification
   ```

3. **Identify Compression Targets**:
   ```python
   targets = identify_targets(analysis, threshold=0.70)
   # Select items for compression based on score
   ```

4. **Calculate Expected Result**:
   ```python
   estimate = calculate_compression_result(targets)
   # Verify we'll achieve target reduction
   ```

### Compression Process

**Step 1: File Content Compression**

```python
def compress_file_contents(files):
    for file in files:
        # Store full content
        db_id = store_file(file.path, file.content, file.metadata)

        # Create pointer
        pointer = create_pointer(
            path=file.path,
            lines=file.line_count,
            size=file.token_count,
            hash=file.content_hash,
            db_id=db_id
        )

        # Replace in context
        replace_content(file, pointer)
```

**Example**:
```
Before (15,000 tokens):
```python
# Full content of src/api/auth.py
class AuthHandler:
    def __init__(self):
        # ... 450 lines of code ...
```

After (100 tokens):
[File: src/api/auth.py, 450 lines, 15KB, hash: abc123, stored: db_12345]
```

**Step 2: Conversation Compression**

```python
def compress_conversations(messages, preserve_recent=30):
    recent = messages[-preserve_recent:]  # Keep recent
    historical = messages[:-preserve_recent]  # Compress older

    # Summarize historical messages
    summary = generate_summary(historical)

    # Store full conversation
    db_id = store_conversation(historical)

    # Create compressed version
    compressed = f"[Summary: {summary}] [Full: db_{db_id}]"

    return compressed + recent
```

**Example**:
```
Before (25,000 tokens):
[50 messages of historical conversation]

After (5,000 tokens):
[Summary: Discussed API authentication implementation. Decided on JWT with refresh tokens stored in Redis. Implemented token generation and validation. Resolved CORS issues. Full conversation: db_12346]
[Recent 10 messages preserved]
```

**Step 3: Command Output Compression**

```python
def compress_command_output(output, command):
    if len(output) < 1000:
        return output  # Keep small outputs

    # Extract key information
    summary = extract_summary(output)
    errors = extract_errors(output)
    warnings = extract_warnings(output)

    # Store full output
    db_id = store_output(output, command)

    # Create compressed version
    return f"""
    [Command: {command}]
    Status: {summary}
    Errors: {errors if errors else 'None'}
    Warnings: {warnings if warnings else 'None'}
    [Full output: db_{db_id}]
    """
```

### Post-Compression Steps

1. **Verify Compression**:
   ```python
   result = verify_compression(original, compressed)
   assert result.ratio <= 0.60  # Target: 60% or less
   assert result.info_preserved >= 0.95  # 95%+ info preserved
   ```

2. **Update Metadata**:
   ```python
   record_compression(
       timestamp=now(),
       original_tokens=original_tokens,
       compressed_tokens=compressed_tokens,
       ratio=ratio,
       items_compressed=len(targets)
   )
   ```

3. **Update Context**:
   ```python
   replace_context(compressed_context)
   update_compression_pointers(pointers)
   ```

## Compression Strategies

### Adaptive Compression

**Context Pressure-Based**:
```python
def get_compression_level(pressure):
    if pressure < 0.60:
        return "none"  # No compression needed
    elif pressure < 0.70:
        return "light"  # 20-30% reduction
    elif pressure < 0.80:
        return "standard"  # 40-50% reduction
    elif pressure < 0.90:
        return "aggressive"  # 60-70% reduction
    else:
        return "maximum"  # 70-80% reduction
```

**Compression Levels**:

| Level | Pressure | Target Reduction | Strategy |
|-------|----------|------------------|----------|
| None | <60% | 0% | No action |
| Light | 60-70% | 20-30% | Compress large files only |
| Standard | 70-80% | 40-50% | 30%-70% algorithm |
| Aggressive | 80-90% | 60-70% | Compress more aggressively |
| Maximum | >90% | 70-80% | Emergency compression |

### Content-Specific Strategies

**File Contents**:
- **Always compress**: Files >10K tokens
- **Usually compress**: Files >5K tokens, not recently modified
- **Sometimes compress**: Files 1-5K tokens, >1 hour old
- **Rarely compress**: Files <1K tokens or recently edited

**Conversations**:
- **Always compress**: Messages >50 old, >1 hour
- **Usually compress**: Messages 20-50 old, >30 min
- **Sometimes compress**: Messages 10-20 old
- **Never compress**: Last 10 messages

**Command Outputs**:
- **Always compress**: Outputs >5K tokens
- **Usually compress**: Outputs >2K tokens
- **Sometimes compress**: Outputs 1-2K tokens
- **Never compress**: Outputs <1K tokens or with errors

## Recovery and Re-expansion

### When to Recover

**Automatic Recovery**:
- User asks about compressed content
- Need to reference old file
- Debugging requires historical context
- Explicit recovery command

**Manual Recovery**:
```bash
/memory:load db_12345  # Load specific content
/memory:expand file src/api/auth.py  # Expand file pointer
/memory:restore session-001  # Restore full session
```

### Recovery Process

```python
def recover_content(pointer):
    # Load from SQLite
    content = load_from_database(pointer.db_id)

    # Verify integrity
    if hash(content) != pointer.hash:
        raise IntegrityError("Content corrupted")

    # Restore to context
    restore_content(pointer.location, content)

    return content
```

### Selective Re-expansion

```python
def selective_expand(query):
    # Find relevant compressed content
    matches = search_compressed_content(query)

    # Expand only relevant sections
    for match in matches:
        if match.relevance > 0.8:
            expand_content(match.pointer)
```

## Integration with Memory Manager

### Compact Workflow

```
1. Detect Trigger
   ├── Context > 60%
   ├── Manual command
   └── PreCompact hook

2. Analyze Context
   ├── Calculate distribution
   ├── Identify targets
   └── Estimate savings

3. Save Original
   ├── Store in SQLite
   ├── Create recovery pointers
   └── Record metadata

4. Execute Compression
   ├── Compress files
   ├── Summarize conversations
   └── Compress outputs

5. Verify Result
   ├── Check token reduction
   ├── Verify info preservation
   └── Update statistics

6. Update Context
   ├── Replace with compressed
   ├── Update pointers
   └── Record compression
```

### Hook Integration

**PreCompact Hook**:
```json
{
  "event": "PreCompact",
  "condition": "context_tokens > 128000 || context_percentage > 0.60",
  "action": "run_compact_strategy",
  "timeout": 30000
}
```

**Hook Behavior**:
1. Triggered before automatic compact
2. Runs context analysis
3. Executes 30%-70% algorithm
4. Stores original in SQLite
5. Replaces context with compressed version

### Storage Integration

**SQLite Tables Used**:
- `context_history` - Full context snapshots
- `compression_pointers` - File/content pointers
- `compression_stats` - Compression metrics
- `compressed_content` - Compressed data

**Storage Strategy**:
```python
def store_compression(context, compressed, metadata):
    # Store full context
    context_id = db.insert('context_history', context)

    # Store compression mapping
    for pointer in compressed.pointers:
        db.insert('compression_pointers', {
            'context_id': context_id,
            'pointer_id': pointer.id,
            'original_location': pointer.location,
            'db_reference': pointer.db_id
        })

    # Store statistics
    db.insert('compression_stats', {
        'context_id': context_id,
        'original_tokens': metadata.original_tokens,
        'compressed_tokens': metadata.compressed_tokens,
        'ratio': metadata.ratio,
        'timestamp': metadata.timestamp
    })
```

## Best Practices

### Compression Timing

**Optimal Times**:
- After completing a subtask
- Before starting new major work
- When context reaches 70%
- After loading many files

**Avoid Compressing**:
- During active debugging
- While referencing multiple files
- In middle of complex task
- When context still growing rapidly

### Information Preservation

**Always Preserve**:
- Recent decisions (why, not just what)
- Active code being modified
- Current task objectives
- Error messages and solutions
- User preferences and constraints

**Safe to Compress**:
- Historical context (>1 hour old)
- Completed subtasks
- Exploratory conversations
- Verbose tool outputs
- Repeated information

### Compression Verification

**Check After Compression**:
```python
def verify_compression_quality(original, compressed):
    checks = {
        'token_reduction': compressed.tokens < original.tokens * 0.60,
        'info_preserved': calculate_info_preservation(original, compressed) > 0.95,
        'pointers_valid': all(p.db_id is not None for p in compressed.pointers),
        'recoverable': test_recovery(compressed.pointers[0])
    }

    return all(checks.values()), checks
```

## Performance Optimization

### Batch Compression

```python
def batch_compress(items, batch_size=10):
    """Compress multiple items in batches for efficiency"""
    for i in range(0, len(items), batch_size):
        batch = items[i:i+batch_size]
        compress_batch(batch)
        commit_to_database()
```

### Incremental Compression

```python
def incremental_compress(last_compressed_index):
    """Only compress new content since last compression"""
    new_content = get_content_since(last_compressed_index)

    if len(new_content) < MIN_SIZE:
        return  # Not enough new content

    compress(new_content)
    update_last_compressed_index()
```

### Lazy Loading

```python
def lazy_load_compressed():
    """Load compressed content on-demand"""
    # Keep pointers in memory
    # Load actual content only when accessed
    return CompressedContentProxy(pointers)
```

## Troubleshooting

**Compression not reducing enough**:
- Increase compression aggressiveness
- Compress more content types
- Use more aggressive summarization
- Check for large uncompressed items

**Information loss after compression**:
- Review compression settings
- Increase preservation zone
- Improve summary quality
- Restore from SQLite if needed

**Compression too slow**:
- Use batch compression
- Reduce analysis depth
- Optimize SQLite queries
- Compress incrementally

**Recovery failures**:
- Check SQLite database integrity
- Verify pointer references
- Test recovery process
- Maintain backup pointers

## Commands Reference

| Command | Purpose | Example |
|---------|---------|---------|
| `/memory:compact` | Manual compression | `/memory:compact` |
| `/memory:analyze` | Check compression need | `/memory:analyze` |
| `/memory:stats` | View context stats | `/memory:stats` |
| `/memory:expand` | Expand compressed content | `/memory:expand db_12345` |
| `/memory:restore` | Restore full context | `/memory:restore session-001` |

## Additional Resources

### Reference Files

- **`references/compression-algorithm.md`** - Detailed algorithm explanation
- **`references/pointer-format.md`** - Pointer specifications
- **`references/recovery-process.md`** - Recovery procedures

### Example Files

- **`examples/compression-plan.json`** - Example compression strategy
- **`examples/before-after.md`** - Compression examples
- **`examples/recovery-test.sh`** - Recovery testing script

For more information, see the context-optimization skill and memory-management skill.
