# Memory Manager Hooks 快速参考

## Hooks 配置概览

| Hook Event | Hook Name | Timeout | Status | Description |
|------------|-----------|---------|--------|-------------|
| **SessionStart** | `init-and-load-memory` | 15s | ✓ | 自动初始化内存系统并加载最近记忆 |
| **PreCompact** | `intelligent-compression` | 30s | ✓ | 智能压缩上下文（30%-70%策略） |
| **PostToolUse** | `auto-save-important-operations` | 5s | ✓ | 自动保存重要操作 |
| **Stop** | `session-end-cleanup` | 15s | ✓ | 会话结束时保存和整理记忆 |

## SessionStart Hook

### 功能
自动初始化内存系统（如需要）+ 加载最近记忆

### 执行流程
```
1. 检查 .claude/memory/long-term/knowledge.db
   ├─ 不存在 → bash ${CLAUDE_PLUGIN_ROOT}/scripts/init-db.sh
   └─ 存在 → 跳过

2. 检查最近会话（7天内）
   ├─ 找到 → /memory:load → 显示摘要
   └─ 未找到 → 静默跳过
```

### 输出示例
```
✓ Memory system initialized
📚 Loaded memory from task-001 (2026-01-28): Working on authentication feature
```

## PreCompact Hook

### 功能
当上下文超过阈值时（>128K 或 >60%），智能压缩上下文

### 压缩策略
- **保留**: 最近 30% 的上下文
- **压缩**: 较旧 70% 的上下文
- **目标**: 减少到原始大小的 ~60%

### 压缩技术
- 文件内容 → 文件路径指针
- 网页内容 → URL + 摘要
- 重复信息 → 只保留最新版本
- 工具输出 → 摘要或移除
- 长对话 → 关键点摘要

### 输出示例
```
🗜️ Context compressed: 128K → 52K tokens (60% reduction)
💾 Original saved to: .claude/memory/context-2026-01-29-001.json
📊 Compressed: 15 files, 3 web pages, 2 conversations
```

## PostToolUse Hook

### 功能
在重要工具操作后自动保存到内存

### 触发条件
- **工具**: Write, Edit, Bash
- **Bash 模式**: git commit, git push, npm test, pytest, cargo test

### 保存规则
**总是保存**:
- Write/Edit 工具（代码变更）
- git commit/push（版本控制）
- 测试通过或修复失败

**跳过保存**:
- 琐碎操作（ls, cat, echo）
- 最近已保存（<2分钟）
- 失败且无用信息

### 输出示例
```
💾 Auto-saved: Write operation on src/auth.py
```

## Stop Hook

### 功能
会话结束时保存记忆并提供总结

### 执行步骤
1. 保存当前会话（/memory:save）
2. 整理记忆（memory-organizer agent）
3. 检查是否需要归档
4. 提供会话总结
5. 建议下一步操作

### 输出示例
```
📊 Session Summary
──────────────────────────────────────────────
⏱️  Duration: 45 minutes
💬 Messages: 23 (12 user, 11 assistant)
🔧 Operations: 8 (5 writes, 2 edits, 1 git commit)
💾 Memory saved: .claude/memory/active-tasks/task-001/
📦 Size: 45K tokens

✅ Task: Implement authentication feature
📝 Progress: JWT auth completed, tests passing

💡 Suggestions:
   • Consider archiving this task (use /memory:archive)
   • Review and organize memory (use /memory:organize)
```

## 常见问题

### Q: 如何禁用某个 hook？
A: 在 `hooks/hooks.json` 中设置 `"enabled": false`

### Q: 如何调整超时时间？
A: 修改 `hooks/hooks.json` 中的 `"timeout"` 值（单位：毫秒）

### Q: SessionStart hook 总是初始化怎么办？
A: 检查 `.claude/memory/long-term/knowledge.db` 是否存在，如果存在则不会重复初始化

### Q: PostToolUse hook 保存太频繁？
A: Hook 内置了防重复逻辑（2分钟内不重复保存），如需调整可修改 prompt

### Q: 如何测试 hooks？
A:
```bash
# 测试 SessionStart
rm -rf .claude/memory && # 重启 Claude Code

# 测试 PostToolUse
echo "test" > test.txt  # 使用 Write 工具

# 测试 Stop
# 正常退出 Claude Code
```

## 文件位置

- **Hooks 配置**: `~/codespace/agent-memeory-management/memory-manager/hooks/hooks.json`
- **初始化脚本**: `~/codespace/agent-memeory-management/memory-manager/scripts/init-db.sh`
- **查询工具**: `~/codespace/agent-memeory-management/memory-manager/scripts/query-memory.py`
- **数据库**: `.claude/memory/long-term/knowledge.db`

## 相关命令

```bash
# 查看统计
/memory:stats

# 保存会话
/memory:save

# 搜索记忆
/memory:search "关键词"

# 加载记忆
/memory:load task-001

# 归档任务
/memory:archive task-001

# 整理记忆
/memory:organize

# 手动压缩
/memory:compact

# 导出数据
/memory:export --task task-001
```

## 性能指标

| Hook | 预期执行时间 | 最大超时 |
|------|-------------|----------|
| SessionStart | 2-5s (无初始化) / 5-10s (有初始化) | 15s |
| PreCompact | 10-20s | 30s |
| PostToolUse | <1s | 5s |
| Stop | 5-10s | 15s |

## 最佳实践

1. **定期检查日志**: 监控 hook 执行情况和错误
2. **调整超时**: 根据实际性能调整超时设置
3. **优化 prompt**: 根据使用情况优化 hook prompt
4. **备份配置**: 修改前备份 hooks.json
5. **测试变更**: 在测试项目中验证配置变更

## 更新日志

### 2026-01-30
- ✓ 修复 JSON 结构错误（移除多余嵌套）
- ✓ 增强 SessionStart hook（添加自动初始化）
- ✓ 更新 hook 名称：load-recent-memory → init-and-load-memory
- ✓ 验证所有 hooks 配置正确

## 参考文档

- [HOOKS_FIX_SUMMARY.md](./HOOKS_FIX_SUMMARY.md) - 详细修复总结
- [README.md](./README.md) - 插件使用指南
- [USAGE_AND_TESTING_GUIDE.md](./USAGE_AND_TESTING_GUIDE.md) - 使用和测试指南
