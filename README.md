# AI Map 指南

本指南介绍如何将 **AI Map** 文档系统移植到任何现有项目中。这套系统的核心目标是解决 AI 在大型项目中的**上下文遗忘**和**幻觉**问题，通过"宏观地图"和"微观路标"让 AI 始终保持对项目架构的清晰认知。

---

## 📂 文档结构 (Document Structure)

AI Map 系统由两个层次的文档构成：

1.  **`ai-map/AI_MAP.md` (总地图)**
    项目的“宪法”和核心索引。它定义了全局架构规范、编码准则，并通过自动化脚本实时同步各子模块的职责摘要。它是 AI 进入项目后的首要参考点。

2.  **各模块目录下的 `CONTEXT.md` (微观路标)**
    分布在各个业务或功能模块中的详细文档。它定义了该模块的**单一职责**、**内部架构**、**对外接口**以及**模块特有的开发规范**。

---

## 🛠️ 目录结构 (Directory Structure)

典型的 AI Map 项目结构布局如下：

```text
.
├── ai-map/                  # AI Map 核心文档目录
│   ├── AI_MAP.md   # 总地图 (项目全局索引)
│   └── INTEGRATION_GUIDE.md # 快速迁移与集成指南
├── tool/
│   └── sync_guide.sh        # 自动化同步工具 (聚合 CONTEXT.md)
├── lib/                     # 源代码 (以 Flutter 为例)
│   ├── features/
│   │   └── my_feature/
│   │       ├── CONTEXT.md   # 模块微观路标 (手动维护/AI 更新)
│   │       └── ...
│   └── ...
└── .git/hooks/pre-commit    # Git 钩子 (确保文档与代码同步提交)
```

---

## 快速开始 (5 步实现 AI 驱动的文档自动化)

### 第 0 步：AI 辅助初始化 (Bootstrap)

如果你在一个现有项目中开始，建议让 AI 助手通过探索代码来为你生成首份地图。**注意：必须要求 AI 遵循下文“第一步”中提供的 Markdown 模板结构。**

> **AI 指令示例：**
> "请深度探索我目前的项目结构和核心代码逻辑，并在 `ai-map/` 目录下为我创建一份 `AI_MAP.md`。
>
> **要求：**
>
> 1. **遵循模板**：必须使用以下结构，特别是包含 `MODULE_INDEX` 的占位符：
>
>    ```markdown
>    # AI Map & Architecture Map
>
>    ## Project Navigation
>
>    <!-- MODULE_INDEX_START -->
>
>    | Module Path | Responsibility Summary |
>    | ----------- | ---------------------- |
>
>    <!-- MODULE_INDEX_END -->
>
>    ## Global Conventions
>
>    (在此填入你探索到的技术栈、架构模式和编码规范)
>    ```
>
> 2. **职责填充**：在模块列表中，基于你的理解填入目前主要目录的职责描述。
> 3. **仅限文档**：请仅负责生成这份概览文档，暂不需要创建任何自动化脚本。"

---

### 第一步：搭建基础设施 (Infrastructure)

如果你选择手动搭建，请按以下结构操作：

#### 1. 创建总地图：`ai-map/AI_MAP.md`

在项目根目录创建 `ai-map` 文件夹，并创建 `AI_MAP.md`。它作为 AI 的入口索引和项目概览。

**模板内容：**

```markdown
# AI Map & Architecture Map

## Project Navigation

<!-- MODULE_INDEX_START -->
<!-- 此区域由 ./tool/sync_guide.sh 自动维护，请勿手动编辑 -->

| Module Path | Responsibility Summary |
| ----------- | ---------------------- |

<!-- MODULE_INDEX_END -->

## Global Conventions

在此处写下项目级的全局规范（例如：命名规则、Git 流程、核心技术栈）。
```

#### 2. 创建同步工具：`tool/sync_guide.sh`

此脚本负责将分散的 `CONTEXT.md` 聚合到总地图。

**通用脚本模板 (Bash):**

```bash
#!/bin/bash
# 定义需要扫描的目录 (空格分隔)
scan_dirs="lib/features lib/core lib/app"
output_file="ai-map/AI_MAP.md"
temp_file="temp_index.md"

mkdir -p ai-map

echo "Starting AI Map Sync..."
echo "| Module Path | Responsibility Summary |" > "$temp_file"
echo "|---|---|" >> "$temp_file"

# 遍历目录并提取责任描述
for dir in $scan_dirs; do
    if [ -d "$dir" ]; then
        find "$dir" -name "CONTEXT.md" | sort | while read -r file; do
            module_path=$(dirname "$file")
            summary=$(sed -n '/## .*Responsibility.*/{n;p;}' "$file" | sed 's/^> //')
            if [ -n "$summary" ]; then
                echo "| $module_path | $summary |" >> "$temp_file"
            fi
        done
    fi
done

# 将扫描结果注入总地图
if [ -f "$output_file" ]; then
    sed -i.bak -e "/<!-- MODULE_INDEX_START -->/,/<!-- MODULE_INDEX_END -->/{
        /<!-- MODULE_INDEX_START -->/{p; r $temp_file
        };
        /<!-- MODULE_INDEX_END -->/p; d;
    }" "$output_file"
    rm "${output_file}.bak" 2>/dev/null
else
    echo "# AI Map\n\n<!-- MODULE_INDEX_START -->" > "$output_file"
    cat "$temp_file" >> "$output_file"
    echo "<!-- MODULE_INDEX_END -->" >> "$output_file"
fi
rm "$temp_file"
echo "$output_file has been updated."
```

_授权：`chmod +x tool/sync_guide.sh`_

---

### 第二步：配置 AI 指令 (System Prompt)

将以下规则添加到您的 AI 助手配置中（如 `.cursorrules`, `.gemini/GEMINI.md` 等）。

```markdown
# AI Map / Documentation Strategy

This project uses a tiered documentation system called "AI Map".

1. **Global Map**: `ai-map/AI_MAP.md`.
2. **Local Context**: Each significant directory contains a `CONTEXT.md`.
   **Your Mandate:**

- **Read First**: Before editing a module, read its `CONTEXT.md`.
- **Update Always**: If you modify logic, you MUST update its `CONTEXT.md`.
- **Sync**: After updating, run `./tool/sync_guide.sh`.
```

---

### 第三步：部署自动化守门员 (Git Hook)

为了防止开发者（或 AI）忘记更新文档，配置 Git Hook 进行强制校验。

**安装脚本：** `.git/hooks/pre-commit`

```bash
#!/bin/bash
staged_files=$(git diff --cached --name-only)
# 检查修改的代码是否同步更新了对应的 CONTEXT.md
echo "$staged_files" | grep "\.dart$" | while read -r file; do
    dir=$(dirname "$file")
    while [[ "$dir" == lib* ]]; do
        if [ -f "$dir/CONTEXT.md" ]; then
            if ! echo "$staged_files" | grep -q "^$dir/CONTEXT.md$"; then
                echo "[AI Map] Missing CONTEXT.md update for: $dir"
                exit 1
            fi
            break
        fi
        dir=$(dirname "$dir")
    done
done
```

---

### 第四步：渐进式工作流 (Workflow)

1.  **代码修改**：像往常一样编写代码。
2.  **触发校验**：执行 `git commit`。
3.  **智能拦截**：如果拦截，直接让 AI：“为我更新 [目录名] 的 CONTEXT.md”。
4.  **AI 更新并同步**：AI 完成文档补全和同步。
5.  **顺利提交**：通过。

---

## 核心价值

- **AI 自我修复**：AI 不再只是代码生成器，它成为了自己所需上下文的维护者。
- **强制一致性**：通过 Git Hook 确保文档永不过时。
- **架构主权**：通过 `CONTEXT.md` 明确规定模块职责，防止 AI 在开发时引入跨层调用。
