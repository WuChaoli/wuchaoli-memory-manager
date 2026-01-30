# 30%-70% Compression Algorithm

## Algorithm Overview

The 30%-70% compression algorithm is designed to maintain context continuity while significantly reducing token usage. It preserves recent, high-value content while compressing older, less critical information.

## Core Principles

### Recency Bias
- Recent content is more likely to be relevant
- Older content can be safely summarized
- Temporal locality matters for context

### Information Density
- Preserve high-density information (decisions, solutions)
- Compress low-density content (verbose outputs, repeated reads)
- Maintain semantic coherence

### Reversibility
- All compressed content stored in SQLite
- Can be restored if needed
- Pointers enable selective re-expansion

## Algorithm Steps

### Step 1: Context Partitioning

```
Total Context: C tokens
├── Preservation Zone (30%): P = C × 0.30
└── Compression Zone (70%): Z = C × 0.70
```

**Preservation Zone** (Recent 30%):
- Last N messages (typically 10-20)
- Current file contents being edited
- Active tool results (last 5 minutes)
- Recent decisions and rationale

**Compression Zone** (Older 70%):
- Historical messages (>20 messages old)
- Old file contents (not recently modified)
- Completed subtask discussions
- Verbose command outputs

### Step 2: Content Analysis

For each item in Compression Zone:

1. **Calculate Compressibility Score**:
   ```
   Score = (Size × Age × Redundancy) / Importance

   Where:
   - Size: Token count
   - Age: Time since creation (hours)
   - Redundancy: Repetition factor (1.0 = unique, 2.0 = seen twice)
   - Importance: Semantic value (1.0 = low, 5.0 = critical)
   ```

2. **Classify Content Type**:
   - File content → Pointer compression
   - Conversation → Summary compression
   - Command output → Excerpt compression
   - Tool result → Reference compression

3. **Determine Compression Ratio**:
   - High compressibility: 90% reduction
   - Medium compressibility: 70% reduction
   - Low compressibility: 50% reduction

### Step 3: Compression Execution

**File Content Compression**:
```python
def compress_file_content(file_content, metadata):
    # Store full content in SQLite
    db_id = store_in_database(file_content, metadata)

    # Create pointer
    pointer = {
        "type": "file_pointer",
        "path": metadata["path"],
        "size": len(file_content),
        "lines": file_content.count('\n'),
        "hash": hash(file_content),
        "db_id": db_id,
        "timestamp": now()
    }

    # Return compressed representation
    return f"[File: {metadata['path']}, {pointer['lines']} lines, stored: {db_id}]"
```

**Conversation Compression**:
```python
def compress_conversation(messages, start_idx, end_idx):
    # Extract key information
    decisions = extract_decisions(messages[start_idx:end_idx])
    solutions = extract_solutions(messages[start_idx:end_idx])
    context = extract_context(messages[start_idx:end_idx])

    # Generate summary
    summary = f"""
    [Summary of messages {start_idx}-{end_idx}:
    Context: {context}
    Decisions: {decisions}
    Solutions: {solutions}]
    """

    # Store full conversation in SQLite
    db_id = store_conversation(messages[start_idx:end_idx])

    return summary + f" [Full conversation: {db_id}]"
```

**Command Output Compression**:
```python
def compress_command_output(output, command):
    if len(output) < 1000:
        return output  # Don't compress small outputs

    # Extract key information
    errors = extract_errors(output)
    warnings = extract_warnings(output)
    summary = extract_summary(output)

    # Store full output
    db_id = store_output(output, command)

    # Return compressed version
    return f"""
    [Command: {command}]
    Status: {summary}
    Errors: {errors}
    Warnings: {warnings}
    [Full output: {db_id}]
    """
```

### Step 4: Compression Verification

```python
def verify_compression(original_context, compressed_context):
    # Measure compression ratio
    original_tokens = count_tokens(original_context)
    compressed_tokens = count_tokens(compressed_context)
    ratio = compressed_tokens / original_tokens

    # Verify information preservation
    key_info_preserved = verify_key_information(
        original_context,
        compressed_context
    )

    # Check target achievement
    target_ratio = 0.60  # 60% of original
    success = (ratio <= target_ratio) and key_info_preserved

    return {
        "success": success,
        "original_tokens": original_tokens,
        "compressed_tokens": compressed_tokens,
        "ratio": ratio,
        "savings": original_tokens - compressed_tokens,
        "info_preserved": key_info_preserved
    }
```

## Compression Strategies by Content Type

### 1. File Contents

**Strategy**: Pointer-based compression

**Compression Ratio**: 95-99%

**Example**:
```
Before (10,000 tokens):
[Full file content of src/api/auth.py with 450 lines]

After (100 tokens):
[File: src/api/auth.py, 450 lines, last modified: 2026-01-29T10:30:00Z, stored: db_12345]
```

### 2. Conversations

**Strategy**: Summary-based compression

**Compression Ratio**: 80-90%

**Example**:
```
Before (5,000 tokens):
User: How should I structure the API?
Assistant: [Detailed explanation of REST API structure...]
User: What about authentication?
Assistant: [Long discussion of JWT vs OAuth...]
User: Let's go with JWT
Assistant: [Implementation details...]

After (500 tokens):
[Summary: Discussed API structure and authentication. Decision: REST API with JWT authentication. Key points: Use Express.js, implement refresh tokens, store in Redis. Full conversation: db_12346]
```

### 3. Command Outputs

**Strategy**: Excerpt-based compression

**Compression Ratio**: 70-90%

**Example**:
```
Before (8,000 tokens):
[Full npm install output with hundreds of packages]

After (800 tokens):
[Command: npm install]
Status: Success, 247 packages installed
Warnings: 3 deprecated packages
Time: 45.2s
[Full output: db_12347]
```

### 4. Tool Results

**Strategy**: Reference-based compression

**Compression Ratio**: 60-80%

**Example**:
```
Before (3,000 tokens):
[Full search results with file contents]

After (600 tokens):
[Search: "authentication" in src/]
Matches: 15 files
Top results:
- src/api/auth.py:45 (JWT implementation)
- src/middleware/auth.js:12 (Auth middleware)
- src/config/auth.json:1 (Auth config)
[Full results: db_12348]
```

## Adaptive Compression

### Dynamic Threshold Adjustment

```python
def calculate_compression_threshold(context_pressure):
    """
    Adjust compression aggressiveness based on context pressure
    """
    if context_pressure < 0.60:
        return 0.70  # Gentle compression
    elif context_pressure < 0.75:
        return 0.80  # Standard compression
    elif context_pressure < 0.90:
        return 0.90  # Aggressive compression
    else:
        return 0.95  # Maximum compression
```

### Content-Aware Compression

```python
def select_compression_strategy(content_type, importance, age):
    """
    Choose compression strategy based on content characteristics
    """
    if importance > 4.0:
        return "preserve"  # Don't compress critical content

    if content_type == "file" and age > 1.0:  # >1 hour old
        return "pointer"
    elif content_type == "conversation" and age > 0.5:  # >30 min old
        return "summary"
    elif content_type == "command_output" and len(content) > 1000:
        return "excerpt"
    else:
        return "keep"  # Keep as-is
```

## Performance Optimization

### Batch Compression

```python
def batch_compress(items, target_ratio=0.60):
    """
    Compress multiple items in a single operation
    """
    # Sort by compressibility score (highest first)
    sorted_items = sorted(items, key=lambda x: x.compressibility_score, reverse=True)

    compressed = []
    current_ratio = 1.0

    for item in sorted_items:
        if current_ratio <= target_ratio:
            break

        compressed_item = compress_item(item)
        compressed.append(compressed_item)

        # Update ratio
        current_ratio = calculate_current_ratio(compressed)

    return compressed
```

### Incremental Compression

```python
def incremental_compress(context, last_compressed_index):
    """
    Only compress new content since last compression
    """
    new_content = context[last_compressed_index:]

    if len(new_content) < MIN_COMPRESSION_SIZE:
        return context  # Not enough new content

    compressed_new = compress(new_content)
    return context[:last_compressed_index] + compressed_new
```

## Compression Metrics

### Key Metrics

1. **Compression Ratio**: `compressed_size / original_size`
2. **Token Savings**: `original_tokens - compressed_tokens`
3. **Information Preservation**: `preserved_key_info / total_key_info`
4. **Compression Time**: Time to execute compression
5. **Recovery Success Rate**: Successful restorations / total attempts

### Target Metrics

- Compression Ratio: ≤ 0.60 (60% or less)
- Token Savings: ≥ 40% reduction
- Information Preservation: ≥ 95%
- Compression Time: < 5 seconds
- Recovery Success Rate: > 99%

## Error Handling

### Compression Failures

```python
def safe_compress(content):
    try:
        compressed = compress(content)

        # Verify compression
        if not verify_compression(content, compressed):
            raise CompressionError("Verification failed")

        return compressed

    except Exception as e:
        # Log error
        log_compression_error(e, content)

        # Fallback: keep original
        return content
```

### Recovery Failures

```python
def safe_recover(pointer):
    try:
        original = load_from_database(pointer.db_id)

        # Verify integrity
        if hash(original) != pointer.hash:
            raise IntegrityError("Hash mismatch")

        return original

    except Exception as e:
        # Log error
        log_recovery_error(e, pointer)

        # Return pointer as fallback
        return f"[Content unavailable: {pointer.path}]"
```

## Best Practices

1. **Always store before compressing**: Never lose original content
2. **Verify after compression**: Ensure information preservation
3. **Use appropriate strategies**: Match compression to content type
4. **Monitor metrics**: Track compression effectiveness
5. **Enable recovery**: Maintain pointers and metadata
6. **Compress incrementally**: Don't wait for critical pressure
7. **Preserve decisions**: Never compress key information
8. **Test recovery**: Regularly verify restoration works

## References

- SQLite storage schema: `sqlite-schema.md`
- Pointer format specification: `pointer-format.md`
- Summary generation guidelines: `summary-guidelines.md`
