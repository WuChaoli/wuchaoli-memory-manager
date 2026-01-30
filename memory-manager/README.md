# Memory Manager

智能记忆管理插件，为 Claude Code 提供完整的记忆管理解决方案。

## 功能特性

### 核心功能

- **会话记忆持久化**: 自动保存和加载会话记忆，无缝衔接工作进度
- **智能 Compact 策略**: 当上下文超过阈值时，智能压缩历史内容，保留关键信息
- **任务驱动组织**: 按任务组织记忆，完成后自动归档到长期存储
- **长期记忆存储**: 使用 SQLite 数据库存储长期记忆，支持全文搜索
- **Serena 集成**: 与 Serena MCP 深度集成，实现项目知识管理

### 智能 Compact

- **触发条件**: 上下文 >128K 或 >60%
- **压缩策略**: 保留后 30% 内容，压缩前 70%
- **智能清理**: 清理文件/网页浏览内容，保留指针
- **按角色分类**: 保存时按 user/assistant 角色分类
- **无损归档**: 压缩前保存原始上下文到 SQLite

### 记忆组织

```
.claude/memory/
├── active-tasks/              # 活跃任务
│   └── task-{id}-{name}/
│       ├── context.json       # 任务元数据
│       ├── sessions/          # 会话记录
│       └── artifacts/         # 相关文件
├── archived-tasks/            # 已归档任务
│   └── YYYY-MM/
└── long-term/                 # 长期知识库
    ├── knowledge.db           # SQLite 数据库
    └── index.json             # 快速索引
```

## 安装

### 前置要求

- Claude Code CLI
- Node.js (用于 Serena MCP)
- SQLite3

### 安装步骤

1. 克隆或下载插件到本地
2. 在 Claude Code 中启用插件：
   ```bash
   cc --plugin-dir /path/to/memory-manager
   ```

## 使用指南

### 命令

| 命令 | 说明 |
|------|------|
| `/memory:save` | 手动保存当前会话记忆 |
| `/memory:load` | 加载指定任务或会话的记忆 |
| `/memory:search` | 搜索历史记忆（支持全文、按任务、按时间、按角色） |
| `/memory:organize` | 整理当前任务的记忆结构 |
| `/memory:export` | 导出记忆数据 |
| `/memory:stats` | 查看记忆统计信息 |
| `/memory:compact` | 手动触发 compact 并重启会话 |
| `/memory:archive` | 归档已完成任务到长期存储 |

### 自动化功能

插件会在以下时机自动工作：

- **会话启动**: 自动加载最近会话记忆
- **上下文超限**: 自动触发智能 compact
- **重要操作后**: 自动保存（文件修改、Git 操作、测试执行）
- **会话结束**: 自动保存并提示归档

### 配置

在项目根目录创建 `.claude/memory-manager.local.md`：

```yaml
---
# 压缩阈值（百分比）
compression_threshold: 60

# 记忆保留时间（天）
retention_days: 30

# 是否启用自动归档提示
auto_archive_prompt: true

# Serena 加载策略
serena_load_strategy:
  enabled: true
  auto_load_conditions:
    - new_task
    - days_since: 7
    - has_updates
---

# Memory Manager 配置

此文件用于配置 memory-manager 插件的行为。
```

## 工作原理

### 三层存储架构

1. **CLAUDE.md**: 静态规则和配置（Claude Code 自动加载）
2. **Serena**: 动态项目知识（按需加载）
3. **Memory Manager**: 会话记忆（自动加载）

### 数据流转

```
会话开始 → 加载 CLAUDE.md + 最近会话 + Serena（按需）
    ↓
工作中 → 实时保存到 SQLite
    ↓
上下文超限 → 智能 compact + 保存原始
    ↓
任务完成 → 归档到 SQLite + 同步到 Serena + 更新 CLAUDE.md
```

## 技术架构

- **存储**: SQLite 数据库（结构化存储 + FTS5 全文搜索）
- **集成**: Serena MCP（项目知识管理）
- **同步**: 自动同步到 CLAUDE.md
- **压缩**: 智能 30%-70% 分区压缩算法

## 开发

### 目录结构

```
memory-manager/
├── .claude-plugin/
│   └── plugin.json          # 插件 manifest
├── commands/                 # 8 个命令
├── agents/                   # 2 个 agents
├── skills/                   # 3 个 skills
├── hooks/                    # 4 个 hooks
│   └── hooks.json
├── scripts/                  # 工具脚本
├── .mcp.json                # Serena MCP 配置
└── README.md
```

## 许可证

MIT License

## 作者

Your Name <your.email@example.com>
