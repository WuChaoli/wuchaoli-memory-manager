---
name: Context Optimization
description: This skill should be used when the user asks to "optimize context", "reduce context size", "analyze context usage", "identify compressible content", or mentions context limits, memory pressure, or token optimization. Provides comprehensive guidance for optimizing Claude Code context usage and identifying compression opportunities.
version: 0.1.0
---

# Context Optimization

## Overview

Context optimization enables efficient use of Claude Code's context window through intelligent analysis, categorization, and compression strategies. This skill provides guidance for identifying compressible content, optimizing context allocation, and maintaining essential information while reducing token usage.

## Core Concepts

### Context Window Management

**Context Limits**:
- Maximum context: ~200K tokens
- Warning threshold: 60% (~120K tokens)
- Critical threshold: 80% (~160K tokens)
- Compact trigger: >128K tokens or >60%

**Context Composition**:
- System prompts and instructions
- CLAUDE.md project rules
- Conversation history (user + assistant)
- Tool call results (file contents, command outputs)
- Loaded memories and knowledge

### Optimization Goals

1. **Preserve Essential Information**:
   - Recent conversation context
   - Active task information
   - Critical decisions and rationale
   - Current file contents

2. **Compress Redundant Content**:
   - Repeated file reads
   - Large command outputs
   - Historical conversations
   - Verbose tool results

3. **Remove Unnecessary Data**:
   - Outdated file contents
   - Superseded decisions
   - Temporary debugging output
   - Duplicate information

## Context Analysis

### Content Categorization

**By Role**:
- **User Messages**: Questions, requests, feedback
- **Assistant Messages**: Responses, explanations, code
- **Tool Results**: File contents, command outputs, search results
- **System Messages**: Prompts, instructions, reminders

**By Importance**:
- **Critical**: Recent decisions, active code, current task
- **Important**: Related context, referenced files, key discussions
- **Useful**: Background information, historical context
- **Redundant**: Repeated content, outdated information

**By Compressibility**:
- **High**: Large file dumps, verbose outputs, repeated reads
- **Medium**: Historical conversations, old tool results
- **Low**: Summaries, decisions, key insights
- **None**: Active conversation, current task context

### Analysis Metrics

**Token Distribution**:
```
Total Context: 150K tokens
├── System (10K) - 7%
├── CLAUDE.md (5K) - 3%
├── Conversation (60K) - 40%
│   ├── Recent (30K) - Keep
│   └── Historical (30K) - Compress
└── Tool Results (75K) - 50%
    ├── File Contents (50K) - Compress
    └── Command Outputs (25K) - Compress
```

**Compression Potential**:
- Identify content that can be reduced by 70-90%
- Calculate expected token savings
- Prioritize high-impact compressions
- Preserve information density

## Optimization Strategies

### 30%-70% Compression Algorithm

**Core Principle**:
- Keep recent 30% intact (full fidelity)
- Compress older 70% (reduce to ~30% of original)
- Result: ~60% of original context size

**Implementation**:
```
Context: 150K tokens
├── Recent 30% (45K) → Keep intact
└── Older 70% (105K) → Compress to 30K
Result: 75K tokens (50% reduction)
```

**Compression Zones**:
1. **Preservation Zone** (Recent 30%):
   - Last N messages (typically 10-20)
   - Current file contents
   - Active tool results
   - Recent decisions

2. **Compression Zone** (Older 70%):
   - Historical conversations → Summaries
   - Old file contents → Pointers
   - Large outputs → Key excerpts
   - Repeated content → References

### Content-Specific Strategies

**File Contents**:
- Replace full file with pointer: `[File: path/to/file.py, 500 lines, last read: timestamp]`
- Keep only changed sections
- Reference line numbers instead of full content
- Store full content in SQLite

**Command Outputs**:
- Summarize long outputs (>1000 tokens)
- Keep only error messages and key results
- Replace verbose logs with status summaries
- Store full output in memory database

**Conversations**:
- Summarize older exchanges
- Preserve key decisions and rationale
- Remove redundant clarifications
- Keep question-answer pairs concise

**Tool Results**:
- Compress search results to matches only
- Summarize web fetches to key points
- Replace large data dumps with schemas
- Keep only relevant excerpts

## Context Analyzer Agent

### When to Trigger

**Automatic Triggers**:
- Context exceeds 60% (120K tokens)
- Before compact operation
- After loading large files
- On user request

**Manual Triggers**:
- `/memory:analyze` command
- Before important operations
- When context feels "heavy"
- For optimization planning

### Analysis Process

1. **Measure Current State**:
   - Total token count
   - Distribution by role
   - Distribution by age
   - Compression potential

2. **Identify Compression Targets**:
   - Large file contents (>5K tokens)
   - Repeated tool results
   - Historical conversations (>20 messages old)
   - Verbose command outputs

3. **Calculate Savings**:
   - Per-item compression ratio
   - Total expected reduction
   - Information loss assessment
   - Priority ranking

4. **Generate Recommendations**:
   - High-priority compressions
   - Safe removal candidates
   - Archive suggestions
   - Optimization strategies

### Analysis Output

**Context Report**:
```
Context Analysis Report
=======================
Total Tokens: 150,000 / 200,000 (75%)

Distribution:
- System: 10,000 (7%)
- Conversation: 60,000 (40%)
- Tool Results: 80,000 (53%)

Compression Opportunities:
1. File: src/large-file.py (15K tokens) → Pointer (50 tokens)
   Savings: 14,950 tokens
2. Command: npm install output (8K tokens) → Summary (200 tokens)
   Savings: 7,800 tokens
3. Historical conversation (25K tokens) → Summary (5K tokens)
   Savings: 20,000 tokens

Total Potential Savings: 42,750 tokens (28.5%)
Recommended Action: Compress now
```

## Optimization Techniques

### Pointer-Based Compression

**File Pointers**:
Replace full file content with metadata pointer:

```json
{
  "type": "file_pointer",
  "path": "src/api/auth.py",
  "size": 500,
  "lines": 450,
  "last_modified": "2026-01-29T10:30:00Z",
  "last_read": "2026-01-29T11:00:00Z",
  "hash": "abc123...",
  "stored_in": "memory_db_id_12345"
}
```

**Benefits**:
- Reduces 10K tokens to ~100 tokens
- Preserves file identity
- Enables re-loading if needed
- Maintains context continuity

### Summary-Based Compression

**Conversation Summaries**:
Replace detailed exchanges with concise summaries:

**Before** (2,000 tokens):
```
User: How do I implement JWT authentication?
Assistant: [Long explanation of JWT...]
User: What about refresh tokens?
Assistant: [Detailed refresh token explanation...]
User: Should I use Redis for storage?
Assistant: [Redis vs alternatives discussion...]
```

**After** (200 tokens):
```
[Summary: Discussed JWT authentication implementation,
including refresh token strategy and Redis for token storage.
Decision: Use Redis with 7-day refresh token expiry.]
```

### Selective Retention

**Keep**:
- Recent messages (last 10-20)
- Key decisions and rationale
- Active file contents
- Current task context
- Error messages and solutions

**Compress**:
- Historical conversations (>20 messages old)
- Old file contents (not recently modified)
- Verbose command outputs
- Repeated tool results

**Remove**:
- Superseded information
- Temporary debugging output
- Duplicate content
- Irrelevant tangents

## Integration with Memory Manager

### Compression Workflow

1. **Detect Pressure**:
   - Monitor context size
   - Trigger at 60% threshold
   - Alert before critical limit

2. **Analyze Content**:
   - Run context-analyzer agent
   - Identify compression targets
   - Calculate savings

3. **Execute Compression**:
   - Apply 30%-70% algorithm
   - Store full content in SQLite
   - Replace with pointers/summaries

4. **Verify Results**:
   - Measure new context size
   - Validate information preservation
   - Update compression stats

### Storage Integration

**Before Compression**:
- Save full context to SQLite
- Record compression metadata
- Create recovery pointers

**After Compression**:
- Update context with compressed version
- Store compression mapping
- Enable re-expansion if needed

**Recovery**:
- Load original content from SQLite
- Restore specific sections
- Selective re-expansion

## Best Practices

### Proactive Optimization

**Regular Monitoring**:
- Check context size periodically
- Identify growth patterns
- Optimize before hitting limits
- Maintain 40-50% usage target

**Preventive Measures**:
- Avoid reading large files unnecessarily
- Summarize command outputs proactively
- Archive completed tasks promptly
- Use targeted file reads (line ranges)

### Compression Timing

**Good Times to Compress**:
- After completing a subtask
- Before starting new work
- When context exceeds 60%
- After loading many files

**Bad Times to Compress**:
- During active debugging
- While referencing multiple files
- In middle of complex task
- When context is still growing

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

## Commands Reference

Context optimization commands:

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/memory:analyze` | Analyze context usage | Check optimization opportunities |
| `/memory:compact` | Trigger compression | Context >60% or manual optimization |
| `/memory:stats` | View context stats | Monitor context health |

## Additional Resources

### Reference Files

Detailed information in `references/`:
- **`compression-algorithm.md`** - 30%-70% algorithm details
- **`pointer-format.md`** - File pointer specifications
- **`summary-guidelines.md`** - Conversation summarization rules

### Example Files

Working examples in `examples/`:
- **`context-analysis.json`** - Sample analysis output
- **`compression-plan.json`** - Example compression strategy
- **`before-after.md`** - Compression examples

## Troubleshooting

**Context still growing after compression**:
- Check for continuous file reads
- Identify source of growth
- Consider more aggressive compression
- Archive completed work

**Information loss after compression**:
- Review compression settings
- Adjust preservation zone size
- Restore from SQLite if needed
- Improve summary quality

**Compression too slow**:
- Reduce analysis depth
- Compress in batches
- Use simpler summarization
- Optimize SQLite queries

For more details, see `references/troubleshooting.md`.

