# wuchaoli 的 Claude 插件市场

个人维护的 Claude Code 插件集合，提供各种生产力工具。

## 插件列表

### 🧠 Memory Manager

智能记忆管理插件，为 Claude Code 提供完整的记忆管理解决方案。

**功能特性：**
- 会话记忆持久化（自动保存/加载）
- 智能上下文压缩（自动触发，节省 token）
- 任务驱动的记忆组织
- SQLite 长期存储 + FTS5 全文搜索
- 与 Serena MCP 深度集成

**主要命令：**
- `/memory:save` - 保存会话
- `/memory:load` - 加载记忆
- `/memory:search` - 搜索历史
- `/memory:archive` - 归档任务

**了解更多：** [memory-manager/README.md](memory-manager/README.md)

## 使用方法

### 方式一：直接加载插件（推荐）

```bash
# 克隆仓库
git clone https://github.com/wuchaoli/wuchaoli-claude-plugin.git

# 启动 Claude Code 时指定插件目录
cd your-project
ccl --plugin-dir ../wuchaoli-claude-plugin/memory-manager
```

### 方式二：配置本地插件市场

```bash
# 添加本地市场
claude config add marketplace /path/to/wuchaoli-claude-plugin/marketplace.json

# 安装插件
claude plugin install memory-manager

# 启动 Claude Code
ccl
```

### 方式三：使用 Release 压缩包

1. 下载 [Releases](https://github.com/wuchaoli/wuchaoli-claude-plugin/releases) 中的插件压缩包
2. 解压到本地目录
3. 使用 `--plugin-dir` 参数加载

## 插件开发

### 目录结构

```
wuchaoli-claude-plugin/
├── marketplace.json          # 市场索引
├── README.md                 # 本文件
└── memory-manager/           # 插件目录
    ├── .claude-plugin/
    │   └── plugin.json       # 插件清单
    ├── commands/             # 命令定义
    ├── agents/               # Agent 定义
    ├── skills/               # Skill 定义
    ├── hooks/                # Hook 配置
    └── README.md             # 插件说明
```

### 添加新插件

1. 在根目录下创建新插件目录：`my-plugin/`
2. 创建插件清单：`my-plugin/.claude-plugin/plugin.json`
3. 编写插件文档：`my-plugin/README.md`
4. 更新市场索引：添加插件信息到 `marketplace.json`

## 配置

### 插件配置

Memory Manager 插件支持自定义配置，在项目根目录创建 `.claude/memory-manager.local.md`：

```yaml
---
# 压缩阈值（百分比）
compression_threshold: 60

# 记忆保留时间（天）
retention_days: 30

# 是否启用自动归档提示
auto_archive_prompt: true
---
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 作者

wuchaoli
