# Memory Manager Plugin - GitHub 仓库设置指南

## 当前状态

✅ 步骤 1: 清理冗余文件 - 已完成
✅ 步骤 2: 复制文件到 ~/codespace/wuchaoli-claude-plugin/ - 已完成
✅ 步骤 3: 初始化 Git 仓库 - 已完成
✅ 步骤 4: 创建初始提交 - 已完成
⏸️  步骤 5: 推送到 GitHub - 需要手动完成
⏸️  步骤 6: 配置 Supermarket - 待推送完成后执行

## 完成步骤 5: 推送到 GitHub

由于网络连接问题，您需要手动完成以下步骤：

### 5.1 在 GitHub 上创建仓库

1. 打开浏览器访问: https://github.com/new

2. 填写仓库信息:
   - **Repository name**: `wuchaoli-memory-manager`
   - **Description**: `Intelligent memory management plugin for Claude Code - session persistence, compression, and long-term storage`
   - **Visibility**: ✓ Public (公开仓库)
   - **不要勾选** "Add a README file" (我们已有)
   - **不要勾选** "Add .gitignore" (我们已有)
   - **不要选择** "Choose a license" (可以稍后添加)

3. 点击 "Create repository" 按钮

### 5.2 推送代码到 GitHub

创建仓库后，在终端运行以下命令:

```bash
cd ~/codespace/wuchaoli-claude-plugin
git push -u origin main
```

或者运行设置脚本:
```bash
cd ~/codespace/wuchaoli-claude-plugin
bash setup-github.sh
```

### 5.3 验证推送成功

推送成功后，访问: https://github.com/wuchaoli/wuchaoli-memory-manager

您应该能看到所有的插件文件。

## 完成步骤 6: 配置 Claude Supermarket

推送成功后，将此仓库添加到 Claude Code 的插件源：

### 6.1 创建或编辑插件源配置

```bash
# 编辑插件源配置
nano ~/.claude/plugins/source.json
```

### 6.2 添加仓库信息

在 `source.json` 中添加以下内容:

```json
{
  "sources": [
    {
      "name": "wuchaoli-memory-manager",
      "url": "https://github.com/wuchaoli/wuchaoli-memory-manager",
      "branch": "main"
    }
  ]
}
```

或者使用命令行添加:
```bash
mkdir -p ~/.claude/plugins
cat > ~/.claude/plugins/source.json << 'EOF'
{
  "sources": [
    {
      "name": "wuchaoli-memory-manager",
      "url": "https://github.com/wuchaoli/wuchaoli-memory-manager",
      "branch": "main"
    }
  ]
}
EOF
```

### 6.3 验证配置

```bash
# 检查配置文件
cat ~/.claude/plugins/source.json

# 刷新插件列表
claude-code --refresh-plugins  # 如果支持此命令
```

## 插件信息

**仓库名称**: wuchaoli-memory-manager
**仓库地址**: https://github.com/wuchaoli/wuchaoli-memory-manager
**插件名称**: memory-manager
**版本**: 0.1.0
**描述**: 智能记忆管理插件 - 会话持久化、智能压缩和长期存储

## 插件功能

- ✅ 会话记忆持久化
- ✅ 智能 compact 策略（30%-70%）
- ✅ 长期记忆存储（SQLite）
- ✅ 任务驱动的记忆组织
- ✅ 完整的 Hooks 集成
  - SessionStart: 自动初始化 + 加载记忆
  - PreCompact: 智能压缩上下文
  - PostToolUse: 自动保存重要操作
  - Stop: 会话结束保存和整理

## 目录结构

```
wuchaoli-memory-manager/
├── agents/                    # Subagent 定义
│   ├── context-analyzer.md    # 上下文分析 agent
│   └── memory-organizer.md    # 记忆整理 agent
├── commands/                  # 斜杠命令
│   ├── archive.md            # 归档任务
│   ├── compact.md            # 压缩上下文
│   ├── export.md             # 导出数据
│   ├── load.md               # 加载记忆
│   ├── organize.md           # 整理记忆
│   ├── save.md               # 保存会话
│   ├── search.md             # 搜索记忆
│   └── stats.md              # 查看统计
├── hooks/                    # Hooks 配置
│   ├── hooks.json            # Hooks 定义
│   └── hooks.json.backup     # 原始备份
├── scripts/                  # 实用脚本
│   ├── init-db.sh           # 初始化数据库
│   ├── query-memory.py      # 查询记忆
│   ├── export-task.sh       # 导出任务
│   ├── test-data-setup.sh   # 测试数据设置
│   └── test-data-cleanup.sh # 测试数据清理
├── skills/                   # 技能文档
│   ├── memory-management/   # 记忆管理技能
│   ├── context-optimization/ # 上下文优化技能
│   └── compact-strategy/    # 压缩策略技能
├── test/                     # 测试文件
│   ├── HOOKS_TESTING_GUIDE.md
│   └── context-analyzer-test-report.md
├── .gitignore               # Git 忽略文件
├── README.md                # 插件说明
├── HOOKS_FIX_SUMMARY.md     # Hooks 修复总结
├── HOOKS_QUICK_REFERENCE.md # Hooks 快速参考
└── setup-github.sh          # GitHub 设置脚本
```

## 使用说明

### 安装插件

1. 添加插件源（见上文 "配置 Claude Supermarket"）

2. 在 Claude Code 中启用插件:
   ```bash
   # 在 Claude Code 设置中启用插件
   # 或运行:
   claude-code --enable-plugin memory-manager
   ```

### 基本使用

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

### Hooks 自动化

插件包含以下自动化 hooks:

- **SessionStart**: 自动初始化数据库 + 加载最近记忆
- **PreCompact**: 上下文超过阈值时自动压缩
- **PostToolUse**: 重要操作后自动保存
- **Stop**: 会话结束时自动保存和整理

## 故障排除

### 问题: 推送失败

**错误**: `Failed to connect to github.com`

**解决方案**:
1. 检查网络连接
2. 配置代理（如果需要）:
   ```bash
   git config --global http.proxy http://proxy.example.com:8080
   git config --global https.proxy https://proxy.example.com:8080
   ```
3. 或使用 SSH 代替 HTTPS:
   ```bash
   git remote set-url origin git@github.com:wuchaoli/wuchaoli-memory-manager.git
   ```

### 问题: 插件未生效

**解决方案**:
1. 确认 `source.json` 配置正确
2. 重启 Claude Code
3. 检查插件是否已启用
4. 查看日志文件

### 问题: 数据库初始化失败

**解决方案**:
1. 检查 sqlite3 是否已安装
2. 手动运行初始化脚本:
   ```bash
   bash ~/.claude/plugins/memory-manager/scripts/init-db.sh
   ```

## 下一步

1. ✅ 完成代码推送
2. ✅ 配置 Supermarket 源
3. ⏭️ 添加 GitHub Actions CI/CD
4. ⏭️ 创建 Releases 和版本标签
5. ⏭️ 编写完整的使用文档
6. ⏭️ 添加示例和教程

## 支持和反馈

- **Issues**: https://github.com/wuchaoli/wuchaoli-memory-manager/issues
- **Discussions**: https://github.com/wuchaoli/wuchaoli-memory-manager/discussions
- **文档**: https://github.com/wuchaoli/wuchaoli-memory-manager/blob/main/README.md

## 许可证

MIT License - 详见 LICENSE 文件
