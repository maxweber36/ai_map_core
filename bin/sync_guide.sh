#!/bin/bash

# ==============================================================================
# 📖 AI Map Sync Tool
# ==============================================================================
# Auto-detects project type (Flutter, Node, Go, Python) and scans for modules.
# Configurable via ai-map/config.sh
# ==============================================================================

GUIDE_FILE="ai-map/AI_MAP.md"
CONTEXT_FILE="CONTEXT.md"
CONFIG_FILE="ai-map/config.sh"

# 默认变量 (可在 config.sh 中覆盖)
HEADER_PROJECT_NAME="Project"
HEADER_TECH_STACK="- **Core**: (Auto-detected or Configured)"
TARGET_DIRS="" # 将由自动探测或配置填充

# 1. 确保在脚本出错时退出
set -e

echo "🚀 Starting AI Map Sync..."

# --- 函数定义 ---

# 自动探测项目类型并设置默认值
detect_project_defaults() {
    if [ -f "pubspec.yaml" ]; then
        echo "✨ Detected Flutter/Dart project"
        TARGET_DIRS="lib/features lib/core lib/app"
        HEADER_TECH_STACK=$(cat <<EOF
- **Core Framework**: Flutter
- **Language**: Dart
- **State Management**: (Check pubspec.yaml)
EOF
)
    elif [ -f "package.json" ]; then
        echo "✨ Detected Node.js/Web project"
        # 尝试常见的源码目录
        if [ -d "src" ]; then
            TARGET_DIRS="src/features src/modules src/components src/pages"
        else
            TARGET_DIRS="app features modules"
        fi
        HEADER_TECH_STACK=$(cat <<EOF
- **Environment**: Node.js / Web
- **Language**: JavaScript / TypeScript
- **Package Manager**: npm/yarn/pnpm
EOF
)
    elif [ -f "go.mod" ]; then
        echo "✨ Detected Go project"
        TARGET_DIRS="internal pkg cmd"
        HEADER_TECH_STACK=$(cat <<EOF
- **Language**: Go
- **Module System**: Go Modules
EOF
)
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        echo "✨ Detected Python project"
        # Python 结构多变，尝试探测 src 或直接扫描当前目录下的包
        if [ -d "src" ]; then
            TARGET_DIRS="src"
        elif [ -d "app" ]; then
            TARGET_DIRS="app"
        else
            # 简单的回退：假设项目名同名的文件夹是源码
            TARGET_DIRS="$(basename "$PWD")"
        fi
        HEADER_TECH_STACK=$(cat <<EOF
- **Language**: Python
- **Environment**: (Virtualenv/Conda recommended)
EOF
)
    else
        echo "⚠️ No specific project type detected. Using generic defaults."
        TARGET_DIRS="src lib modules"
        HEADER_TECH_STACK="- **Type**: Generic Project"
    fi
}

# 允许用户覆盖的 Header 生成器
generate_guide_header() {
    # 如果用户没有在 config.sh 中重定义此函数，将使用以下默认模板
    cat <<EOF
# 📖 AI MAP: $HEADER_PROJECT_NAME

> 🤖 **AI & Developer Readme**
> This document is the "Constitution" of the project. It defines core architecture, standards, and the module map.
> **Note:** The "Module Index" below is auto-generated. Please modify $CONTEXT_FILE in each module directory and run bin/sync_guide.sh to update.

## 🏗️ 架构概览 (Architecture)
$HEADER_TECH_STACK

## 📏 开发准则 (Principles)
1. **Single Responsibility**: Each module defines its boundary via $CONTEXT_FILE.
2. **Decoupling**: Avoid strong coupling between modules.
3. **Interface First**: Read and update the Interface section in $CONTEXT_FILE before changing code.

EOF
}

generate_context_template() {
    local module_name=$1
    cat <<EOF
# $module_name Context

## 🎯 职责 (Responsibility)
> Describe the core responsibility of this module in one sentence here. (Synced to $GUIDE_FILE).

## 🏗️ 内部架构 (Internal Architecture)
<!-- Describe logic flow and key classes -->
- Components: ...
- Logic: ...

## 🔌 接口协议 (Public Interface)
<!-- How do other modules interact with this one? -->
- **Exports**: ...
- **API**: ...

## 📏 规范 (Standards)
<!-- Module specific rules -->

<!-- AI_INSTRUCTION: Update this file when changing module structure -->
EOF
}

# --- 初始化与配置 ---

# 1. 运行自动探测
detect_project_defaults

# 2. 加载用户配置（如果存在），覆盖自动探测的结果
if [ -f "$CONFIG_FILE" ]; then
    echo "⚙️  Loading configuration from $CONFIG_FILE..."
    # 使用 source 导入，允许覆盖变量和函数
    source "$CONFIG_FILE"
fi

# 检查 TARGET_DIRS 是否有效，如果为空或目录不存在，给出警告但继续（可能只是一些目录不存在）
FINAL_DIRS=""
for dir in $TARGET_DIRS; do
    if [ -d "$dir" ]; then
        FINAL_DIRS="$FINAL_DIRS $dir"
    else
        echo "⚠️  Target directory not found (skipping): $dir"
    fi
done

if [ -z "$FINAL_DIRS" ]; then
    echo "❌ No valid target directories found to scan."
    echo "   Configured targets: $TARGET_DIRS"
    echo "   Please check your project structure or create '$CONFIG_FILE' to specify 'TARGET_DIRS'."
    exit 1
fi

# --- 主逻辑 (扫描与生成) ---

# 创建临时文件
MODULES_BUFFER=$(mktemp)

# 写入表头
echo "## 📂 模块索引 (Module Index)" >> "$MODULES_BUFFER"
echo "" >> "$MODULES_BUFFER"
echo "| Module | Responsibility | Context |" >> "$MODULES_BUFFER"
echo "| :--- | :--- | :---: |" >> "$MODULES_BUFFER"

echo "🔍 Scanning directories: $FINAL_DIRS"

for parent_dir in $FINAL_DIRS; do
    # 遍历子目录
    for module_path in "$parent_dir"/*; do
        if [ -d "$module_path" ]; then
            module_name=$(basename "$module_path")
            context_path="$module_path/$CONTEXT_FILE"
            responsibility="*(Pending)*"

            # 1. 检查并生成模板
            if [ ! -f "$context_path" ]; then
                echo "   📝 Scaffolding $CONTEXT_FILE for: $module_name"
                generate_context_template "$module_name" > "$context_path"
            else
                # 2. 提取职责
                # 逻辑：查找 '## 🎯' 下方的第一个以 '>' 开头的行，并去掉 '>'
                extracted=$(awk '/## 🎯/{flag=1; next} /##/{flag=0} flag && /^>/{print substr($0, 3); exit}' "$context_path" || true)
                if [ ! -z "$extracted" ]; then
                    responsibility="$extracted"
                fi
            fi

            # 3. 添加到表格
            clean_path=${module_path#./}
            # 生成相对链接
            echo "| $clean_path | $responsibility | [View](../$clean_path/$CONTEXT_FILE) |" >> "$MODULES_BUFFER"
        fi
    done
done

# --- 组装最终文件 ---

# 确保输出目录存在
mkdir -p "$(dirname "$GUIDE_FILE")"

generate_guide_header > "$GUIDE_FILE"
echo "" >> "$GUIDE_FILE"
cat "$MODULES_BUFFER" >> "$GUIDE_FILE"
echo "" >> "$GUIDE_FILE"
echo "---" >> "$GUIDE_FILE"
echo "*Last synced: $(date)*" >> "$GUIDE_FILE"

rm "$MODULES_BUFFER"

echo "✅ $GUIDE_FILE has been updated."