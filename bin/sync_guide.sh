#!/bin/bash

# ==============================================================================
# 📖 AI Map Sync Tool
# ==============================================================================
# Auto-detects project type (Flutter, Node, Go, Python) and scans for modules.
# TARGET_DIRS can be configured via ai-map/config.sh
# ==============================================================================

GUIDE_FILE="ai-map/AI_MAP.md"
CONTEXT_FILE="CONTEXT.md"
CONFIG_FILE="ai-map/config.sh"

# 默认变量
TARGET_DIRS="" # 将由自动探测或配置填充

# 仅用于初始化骨架，不从 config 覆盖
HEADER_PROJECT_NAME_PLACEHOLDER="（由 AI 在初始化后补全项目名）"
HEADER_TECH_STACK_PLACEHOLDER=$(cat <<EOF
- **技术栈**:（由 AI 在初始化后补全）
EOF
)

# 1. 确保在脚本出错时退出
set -e

usage() {
    cat <<EOF
Usage:
  ./bin/sync_guide.sh --init    Initialize AI_MAP.md and scaffold CONTEXT.md templates
  ./bin/sync_guide.sh --sync    Sync module responsibilities into AI_MAP.md
  ./bin/sync_guide.sh --init --force-map       Force reinitialize AI_MAP.md
  ./bin/sync_guide.sh --init --force-context   Force reinitialize CONTEXT.md
  ./bin/sync_guide.sh --init --force-all       Force reinitialize AI_MAP.md and CONTEXT.md
EOF
}

MODE=""
FORCE_MAP="false"
FORCE_CONTEXT="false"
FORCE_ALL="false"
args=("$@")
for arg in "${args[@]}"; do
    case "$arg" in
        --force-map)
            FORCE_MAP="true"
            ;;
        --force-context)
            FORCE_CONTEXT="true"
            ;;
        --force-all)
            FORCE_ALL="true"
            ;;
    esac
done

case "${1:-}" in
    --init)
        MODE="init"
        ;;
    --sync)
        MODE="sync"
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        usage
        exit 1
        ;;
esac

if [ "$MODE" != "init" ] && { [ "$FORCE_MAP" = "true" ] || [ "$FORCE_CONTEXT" = "true" ] || [ "$FORCE_ALL" = "true" ]; }; then
    echo "❌ --force-map/--force-context/--force-all 仅可与 --init 一起使用。"
    exit 1
fi

echo "🚀 Starting AI Map Sync ($MODE)..."

# --- 函数定义 ---

# 自动探测项目类型并设置默认值
detect_project_defaults() {
    if [ -f "pubspec.yaml" ]; then
        echo "✨ Detected Flutter/Dart project"
        TARGET_DIRS="lib/features lib/core lib/app"
    elif [ -f "package.json" ]; then
        echo "✨ Detected Node.js/Web project"
        # 尝试常见的源码目录
        if [ -d "src" ]; then
            TARGET_DIRS="src/features src/modules src/components src/pages"
        else
            TARGET_DIRS="app features modules"
        fi
    elif [ -f "go.mod" ]; then
        echo "✨ Detected Go project"
        TARGET_DIRS="internal pkg cmd"
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
    else
        echo "⚠️ No specific project type detected. Using generic defaults."
        TARGET_DIRS="src lib modules"
    fi
}

# Header 生成器（仅用于骨架）
generate_guide_header() {
    cat <<EOF
# 📖 AI MAP: $HEADER_PROJECT_NAME_PLACEHOLDER

> 🤖 **AI & Developer Readme**
> This document is the "Constitution" of the project. It defines core architecture, standards, and the module map.
> **Note:** The "Module Index" below is auto-generated. Please modify $CONTEXT_FILE in each module directory and run bin/sync_guide.sh --sync to update.

## 🏗️ 架构概览 (Architecture)
$HEADER_TECH_STACK_PLACEHOLDER

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

# 初始化骨架仅使用占位符，避免被 config 覆盖
HEADER_PROJECT_NAME_PLACEHOLDER="（由 AI 在初始化后补全项目名）"
HEADER_TECH_STACK_PLACEHOLDER=$(cat <<EOF
- **技术栈**:（由 AI 在初始化后补全）
EOF
)

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
    if [ "$MODE" = "sync" ]; then
        echo "❌ No valid target directories found to scan."
        echo "   Configured targets: $TARGET_DIRS"
        echo "   Please check your project structure or create '$CONFIG_FILE' to specify 'TARGET_DIRS'."
        exit 1
    fi
fi

# --- 主逻辑 (扫描与生成) ---

# 创建临时文件
MODULES_TABLE=$(mktemp)

# 写入表头
echo "| Module | Responsibility | Context |" >> "$MODULES_TABLE"
echo "| :--- | :--- | :---: |" >> "$MODULES_TABLE"

INITIALIZED_MODULES=()
EXISTING_MODULES=()

if [ -n "$FINAL_DIRS" ]; then
    echo "🔍 Scanning directories: $FINAL_DIRS"
    for parent_dir in $FINAL_DIRS; do
        # 遍历子目录
        for module_path in "$parent_dir"/*; do
            if [ -d "$module_path" ]; then
                module_name=$(basename "$module_path")
                clean_path=${module_path#./}
                context_path="$module_path/$CONTEXT_FILE"
                responsibility="*(Pending)*"

                # 1. 检查并生成模板（init/sync 都会补全缺失模板）
                if [ ! -f "$context_path" ] || [ "$FORCE_CONTEXT" = "true" ] || [ "$FORCE_ALL" = "true" ]; then
                    echo "   📝 Scaffolding $CONTEXT_FILE for: $module_name"
                    generate_context_template "$module_name" > "$context_path"
                    INITIALIZED_MODULES+=("$clean_path")
                else
                    EXISTING_MODULES+=("$clean_path")
                fi

                # 2. 仅在 sync 模式提取职责
                if [ "$MODE" = "sync" ] && [ -f "$context_path" ]; then
                    # 逻辑：查找 '## 🎯' 下方的第一个以 '>' 开头的行，并去掉 '>'
                    extracted=$(awk '/## 🎯/{flag=1; next} /##/{flag=0} flag && /^>/{print substr($0, 3); exit}' "$context_path" || true)
                    if [ ! -z "$extracted" ]; then
                        responsibility="$extracted"
                    fi
                fi

                # 3. 添加到表格
                # 生成相对链接
                echo "| $clean_path | $responsibility | [View](../$clean_path/$CONTEXT_FILE) |" >> "$MODULES_TABLE"
            fi
        done
    done
else
    echo "ℹ️  No target directories found. Will only generate $GUIDE_FILE."
fi

# --- 组装最终文件 ---

MODULES_SECTION=$(mktemp)
echo "## 📂 模块索引 (Module Index)" >> "$MODULES_SECTION"
echo "" >> "$MODULES_SECTION"
echo "<!-- MODULE_INDEX_START -->" >> "$MODULES_SECTION"
cat "$MODULES_TABLE" >> "$MODULES_SECTION"
echo "<!-- MODULE_INDEX_END -->" >> "$MODULES_SECTION"

update_last_synced() {
    local file_path=$1
    local now
    now=$(date)
    local tmp
    tmp=$(mktemp)
    awk -v now="$now" '
        BEGIN { updated=0 }
        /^\*Last synced:/ || /^_Last synced:/ {
            print "*Last synced: " now "*"
            updated=1
            next
        }
        { print }
        END {
            if (updated == 0) {
                print ""
                print "---"
                print "*Last synced: " now "*"
            }
        }
    ' "$file_path" > "$tmp"
    mv "$tmp" "$file_path"
}

write_new_guide() {
    generate_guide_header > "$GUIDE_FILE"
    echo "" >> "$GUIDE_FILE"
    cat "$MODULES_SECTION" >> "$GUIDE_FILE"
    echo "" >> "$GUIDE_FILE"
    echo "---" >> "$GUIDE_FILE"
    echo "*Last synced: $(date)*" >> "$GUIDE_FILE"
}

print_init_summary() {
    if [ ${#INITIALIZED_MODULES[@]} -eq 0 ] && [ ${#EXISTING_MODULES[@]} -eq 0 ]; then
        echo "ℹ️  未发现可初始化的模块。"
        return
    fi
    echo "📋 CONTEXT.md 初始化清单:"
    if [ ${#INITIALIZED_MODULES[@]} -gt 0 ]; then
        echo "  - 新建:"
        for m in "${INITIALIZED_MODULES[@]}"; do
            echo "    - $m"
        done
    fi
    if [ ${#EXISTING_MODULES[@]} -gt 0 ]; then
        echo "  - 已存在:"
        for m in "${EXISTING_MODULES[@]}"; do
            echo "    - $m"
        done
    fi
}

# 确保输出目录存在
mkdir -p "$(dirname "$GUIDE_FILE")"

if [ "$MODE" = "init" ] || [ ! -f "$GUIDE_FILE" ]; then
    if [ "$MODE" = "init" ] && [ -f "$GUIDE_FILE" ] && [ "$FORCE_MAP" != "true" ] && [ "$FORCE_ALL" != "true" ]; then
        echo "ℹ️  $GUIDE_FILE already exists. Skipping init."
        echo "   Use --force-map or --force-all to reinitialize the document."
    else
        write_new_guide
    fi
else
    if grep -q "<!-- MODULE_INDEX_START -->" "$GUIDE_FILE" && grep -q "<!-- MODULE_INDEX_END -->" "$GUIDE_FILE"; then
        tmp_guide=$(mktemp)
        # 使用管道方式读取表格，避免 awk 内变量换行问题
        awk '
            /<!-- MODULE_INDEX_START -->/ {
                print
                while ((getline line < "'"$MODULES_TABLE"'") > 0) {
                    print line
                }
                skip=1
                next
            }
            /<!-- MODULE_INDEX_END -->/ {
                print
                skip=0
                next
            }
            !skip { print }
        ' "$GUIDE_FILE" > "$tmp_guide"
        mv "$tmp_guide" "$GUIDE_FILE"
        update_last_synced "$GUIDE_FILE"
    else
        echo "⚠️  MODULE_INDEX markers not found. Regenerating $GUIDE_FILE."
        write_new_guide
    fi
fi

rm "$MODULES_TABLE" "$MODULES_SECTION"

if [ "$MODE" = "init" ]; then
    print_init_summary
fi

echo "✅ $GUIDE_FILE has been updated."
