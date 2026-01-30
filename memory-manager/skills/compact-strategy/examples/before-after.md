# Compression Before & After Examples

## Example 1: File Content Compression

### Before (15,000 tokens)
```python
# Full file content of src/api/auth.py (450 lines)
[Complete Python code with all implementations]
```

### After (100 tokens)
```
[File: src/api/auth.py, 450 lines, 15KB, hash: a1b2c3d4, stored: db_12345]
```

**Savings**: 14,900 tokens (99.3% reduction)

---

## Example 2: Conversation Compression

### Before (25,000 tokens)
```
[50 messages discussing JWT authentication implementation]
User: How should I implement JWT?
Assistant: [Detailed explanation...]
User: What about refresh tokens?
Assistant: [Long discussion...]
[... 46 more message pairs ...]
```

### After (5,000 tokens)
```
[Summary: Discussed JWT authentication implementation. Key decisions:
- Use HS256 algorithm with secret key
- 15-minute access token expiry
- 7-day refresh token expiry
- Store refresh tokens in Redis
- Implement token rotation
- Add CORS support
Full conversation: db_12346]

[Recent 10 messages preserved intact]
```

**Savings**: 20,000 tokens (80% reduction)

---

## Example 3: Command Output Compression

### Before (8,000 tokens)
```bash
$ npm install
npm WARN deprecated package1@1.0.0
npm WARN deprecated package2@2.0.0
[... 200 lines of package installation logs ...]
added 247 packages, removed 3 packages, changed 12 packages
[... detailed dependency tree ...]
```

### After (800 tokens)
```
[Command: npm install]
Status: Success, 247 packages installed, 3 removed, 12 changed
Warnings: 2 deprecated packages (package1, package2)
Time: 45.2s
[Full output: db_12347]
```

**Savings**: 7,200 tokens (90% reduction)

---

## Complete Context Compression Example

### Before Compression
```
Total Context: 150,000 tokens (75% of limit)

Distribution:
- System prompts: 10,000 tokens
- User messages: 25,000 tokens
- Assistant messages: 35,000 tokens
- Tool results: 80,000 tokens
  - File contents: 50,000 tokens
  - Command outputs: 25,000 tokens
  - Other tools: 5,000 tokens
```

### After Compression (30%-70% Algorithm)
```
Total Context: 76,500 tokens (38% of limit)

Distribution:
- System prompts: 10,000 tokens (preserved)
- Recent conversation (30%): 18,000 tokens (preserved)
- Compressed conversation (70%): 12,000 tokens (from 42,000)
- Compressed tool results: 36,500 tokens (from 80,000)
  - File pointers: 500 tokens (from 50,000)
  - Command summaries: 6,000 tokens (from 25,000)
  - Other tools: 5,000 tokens (preserved)

Preservation Zone (30%): 45,000 tokens → 45,000 tokens (kept intact)
Compression Zone (70%): 105,000 tokens → 31,500 tokens (70% reduction)
```

**Total Savings**: 73,500 tokens (49% reduction)
**Target Achievement**: ✅ Below 60% target (38% actual)
