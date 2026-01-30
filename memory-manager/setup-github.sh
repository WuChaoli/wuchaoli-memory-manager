#!/bin/bash

# Memory Manager Plugin - GitHub 仓库设置脚本
# 此脚本将帮助您在 GitHub 上创建仓库并推送代码

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Memory Manager Plugin - GitHub 仓库设置                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

REPO_NAME="wuchaoli-memory-manager"
USERNAME="wuchaoli"
GITHUB_URL="https://github.com/${USERNAME}/${REPO_NAME}"

echo "📋 仓库信息:"
echo "  用户名: ${USERNAME}"
echo "  仓库名: ${REPO_NAME}"
echo "  URL: ${GITHUB_URL}"
echo ""

# 检查是否已登录 GitHub
echo "🔐 检查 GitHub 认证..."
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0")
    echo "  找到 gh 命令，版本: ${GH_VERSION}"

    # 检查是否是官方 GitHub CLI
    if gh auth status &> /dev/null 2>&1; then
        echo "  ✓ 已登录 GitHub CLI"

        # 尝试创建仓库
        echo ""
        echo "📦 创建 GitHub 仓库..."
        if gh repo create ${REPO_NAME} --public --source=. --push --description "Intelligent memory management plugin for Claude Code - session persistence, compression, and long-term storage" 2>&1; then
            echo "✓ 仓库创建成功！"
            echo ""
            echo "🌐 仓库地址: ${GITHUB_URL}"
            echo ""
            echo "📚 Claude Supermarket 安装:"
            echo "   在 Claude Code 的插件市场中添加以下 URL:"
            echo "   ${GITHUB_URL}"
            exit 0
        else
            echo "⚠️  自动创建失败，尝试手动推送..."
        fi
    else
        echo "  ℹ️  GitHub CLI 未登录或不是官方版本"
    fi
else
    echo "  ℹ️  未找到 GitHub CLI"
fi

echo ""
echo "📝 手动创建仓库步骤:"
echo ""
echo "1. 在浏览器中打开: https://github.com/new"
echo ""
echo "2. 填写仓库信息:"
echo "   - Repository name: ${REPO_NAME}"
echo "   - Description: Intelligent memory management plugin for Claude Code"
echo "   - Public: ✓ 公开仓库"
echo "   - 不要勾选 'Add a README file'（已有）"
echo "   - 不要勾选 '.gitignore'（已有）"
echo ""
echo "3. 点击 'Create repository'"
echo ""
echo "4. 创建完成后，运行以下命令推送代码:"
echo ""
echo "   cd $(pwd)"
echo "   git push -u origin main"
echo ""
echo "5. 等待推送完成后，仓库地址: ${GITHUB_URL}"
echo ""

# 询问是否继续
read -p "是否已经创建了仓库？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "📤 推送代码到 GitHub..."
    if git push -u origin main; then
        echo ""
        echo "✅ 推送成功！"
        echo ""
        echo "🌐 仓库地址: ${GITHUB_URL}"
        echo ""
        echo "📚 Claude Supermarket 配置:"
        echo "   在 ~/.claude/plugins/source.json 中添加:"
        echo ""
        echo '   {'
        echo '     "name": "wuchaoli-memory-manager",'
        echo '     "url": "'${GITHUB_URL}'",'
        echo '     "branch": "main"'
        echo '   }'
        echo ""
    else
        echo ""
        echo "❌ 推送失败，请检查:"
        echo "  1. 仓库是否已创建"
        echo "  2. 网络连接是否正常"
        echo "  3. 是否有推送权限"
    fi
else
    echo ""
    echo "ℹ️  请完成仓库创建后，再次运行此脚本"
    echo "   或手动执行: git push -u origin main"
fi
