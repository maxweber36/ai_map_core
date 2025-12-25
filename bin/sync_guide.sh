#!/bin/bash

# ==============================================================================
# 📖 AI Map Sync Tool (Fixed)
# ==============================================================================

GUIDE_FILE="ai-map/AI_MAP.md"
CONTEXT_FILE="CONTEXT.md"
TARGET_DIRS="lib/features lib/core lib/app"

# 1. 确保在脚本出错时退出
set -e

echo "🚀 Starting AI Map Sync..."

# --- 函数定义 ---

generate_guide_header() {
    # 使用单引号 EOF 防止任何扩展，除了我们需要手动插入变量的地方
    cat <<EOF
# 📖 AI MAP

> 🤖 **AI 与开发者必读**
> 本文档是项目的“宪法”。它定义了项目的核心架构、开发规范和模块地图。
> **注意：** 下方的“模块索引”由脚本自动生成。请修改各模块目录下的 
$CONTEXT_FILE
，然后运行 
tool/sync_guide.sh
 同步。

## 🏗️ 全局架构规范 (Global Architecture)
- **核心框架**: Flutter
- **状态管理**: Riverpod 2.x
- **路由管理**: GoRouter
- **本地存储**: Isar Database
- **设计风格**: Material 3 / Pixel Art

## 📏 开发准则 (Principles)
1. **单一职责**: 每个模块应通过 
$CONTEXT_FILE
 明确其职责边界。
2. **解耦原则**: 模块间应避免强耦合，遵循依赖倒置。
3. **接口优先**: 修改模块前，先阅读并更新其 
$CONTEXT_FILE
 中的接口章节。

EOF
}

generate_context_template() {
    local module_name=$1
    # 注意：这里我们使用 EOF 而非 'EOF' 因为我们需要 $module_name
    # 但是我们需要小心转义反引号
    cat <<EOF
# $module_name 模块上下文

## 🎯 职责 (Responsibility)
> 请在此处用一句话描述该模块的核心职责（此行会被同步到 
$GUIDE_FILE
）。

## 🏗️ 内部架构 (Internal Architecture)
<!-- 描述该模块的内部逻辑流和关键类 -->
- 
View
: 页面与组件
- 
Controller
: 状态管理逻辑
- 
Repository
: 数据交互

## 🔌 接口协议 (Public Interface)
<!-- 外部模块如何与此模块交互？ -->
- **Exposed Providers**: ...
- **Routes**: ...

## 📏 模块开发规范 (Standards)
<!-- 该模块特有的规则 -->
- 例如：所有数据库操作必须加事务。

<!-- AI_INSTRUCTION: 修改代码结构时请同步更新此文档 -->
EOF
}

# --- 主逻辑 ---

# 创建临时文件
MODULES_BUFFER=$(mktemp)

# 写入表头
echo "## 📂 模块索引 (Module Index)" >> "$MODULES_BUFFER"
echo "" >> "$MODULES_BUFFER"
echo "| 模块路径 | 职责摘要 | 详细上下文 |" >> "$MODULES_BUFFER"
echo "| :--- | :--- | :---: |" >> "$MODULES_BUFFER"

for parent_dir in $TARGET_DIRS; do
    if [ ! -d "$parent_dir" ]; then
        continue
    fi

    echo "🔍 Scanning: $parent_dir"
    
    # 遍历子目录
    for module_path in "$parent_dir"/*; do
        if [ -d "$module_path" ]; then
            module_name=$(basename "$module_path")
            context_path="$module_path/$CONTEXT_FILE"
            responsibility="*(待补充)*"

            # 1. 检查并生成模板
            if [ ! -f "$context_path" ]; then
                echo "   📝 Scaffolding $CONTEXT_FILE for: $module_name"
                generate_context_template "$module_name" > "$context_path"
            else
                # 2. 提取职责
                # 逻辑：查找 '## 🎯' 下方的第一个以 '>' 开头的行，并去掉 '>'
                # 使用 || true 防止 awk 没找到匹配时导致 set -e 退出
                extracted=$(awk '/## 🎯/{flag=1; next} /##/{flag=0} flag && /^>/{print substr($0, 3); exit}' "$context_path" || true)
                if [ ! -z "$extracted" ]; then
                    responsibility="$extracted"
                fi
            fi

            # 3. 添加到表格
            clean_path=${module_path#./}
            # 这里的链接应该是相对于根目录的，因为 GUIDE_FILE 在 ai-map/ 下，所以需要 ../
            echo "| 
$clean_path
 | $responsibility | [查看上下文](../$clean_path/$CONTEXT_FILE) |
" >> "$MODULES_BUFFER"
        fi
    done
done

# --- 组装最终文件 ---

generate_guide_header > "$GUIDE_FILE"
echo "" >> "$GUIDE_FILE"
cat "$MODULES_BUFFER" >> "$GUIDE_FILE"
echo "" >> "$GUIDE_FILE"
echo "---" >> "$GUIDE_FILE"
echo "*Last synced: $(date)*" >> "$GUIDE_FILE"

rm "$MODULES_BUFFER"

echo "✅ $GUIDE_FILE has been updated."