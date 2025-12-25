# AI Map 指南

本指南介绍如何将 **AI Map** 文档系统移植到任何现有项目中。这套系统的核心目标是解决 AI 在软件项目中的**上下文遗忘**和**幻觉**问题，通过"宏观地图"和"微观路标"让 AI 始终保持对项目架构的清晰认知。

---

## 📂 文档结构 (Document Structure)

AI Map 系统由两个层次的文档构成：

1.  **`ai-map/AI_MAP.md` (总地图)**
    项目的“宪法”和核心索引。它定义了全局架构规范、编码准则，并通过自动化脚本实时同步各子模块的职责摘要。它是 AI 进入项目后的首要参考点。

2.  **各模块目录下的 `CONTEXT.md` (微观路标)**
    分布在各个业务或功能模块中的详细文档。它定义了该模块的**单一职责**、**内部架构**、**对外接口**以及**模块特有的开发规范**。

### 🔄 信息流向 (Information Flow)

```text
       [ AI Assistant ]
              |
              | 1. Reads
              v
      [ ai-map/AI_MAP.md ] <-------+
      (Global Index/Rules)         |
              |                    | 4. Auto-Sync
              | 2. Guides          | (via sync_guide.sh)
              v                    |
      [ Module/CONTEXT.md ] -------+
      (Local Context/Spec)
              ^
              | 3. Enforces Consistency
              | (via Git Hook)
              v
      [ Source Code ]
```

---

## 🛠️ 目录结构 (Directory Structure)

典型的 AI Map 项目结构布局如下：

```text
.
├── ai-map/                  # AI Map 核心文档目录
│   ├── AI_MAP.md            # 总地图 (项目全局索引)
│   ├── config.sh            # [可选] 项目配置文件 (自定义扫描路径等)
│   └── INTEGRATION.md       # 快速迁移与集成指南
├── bin/
│   └── sync_guide.sh        # 自动化同步工具 (聚合 CONTEXT.md)
├── lib/                     # 源代码 (以 Flutter 为例，支持任意语言)
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

如果你在一个现有项目中开始，建议让 AI 助手通过探索代码来为你生成首份地图。

> **提示**：AI 辅助初始化 prompt 已存储在 `ai-map/INITIALIZE_PROMPT.md`，可直接复制使用。

### 第一步：安装工具脚本

复制 `bin/sync_guide.sh` 到你的项目 `bin/` 目录（或其他工具目录），并赋予执行权限。

```bash
mkdir -p bin
cp /path/to/ai-map-core/bin/sync_guide.sh bin/
chmod +x bin/sync_guide.sh
```

**✨ 智能特性：**
该脚本现已支持 **自动探测 (Auto-detect)** 项目类型。

- **Flutter**: 自动扫描 `lib/features`, `lib/core`
- **Node.js**: 自动扫描 `src/modules`, `src/features` 等
- **Go**: 自动扫描 `internal`, `pkg`
- **Python**: 自动探测源码目录

### 第二步：高级配置 (可选)

如果自动探测不满足需求，或者你想自定义扫描路径，请创建 `ai-map/config.sh`：

```bash
# ai-map/config.sh 示例

# 自定义项目名称
HEADER_PROJECT_NAME="My Super App"

# 强制指定扫描目录 (空格分隔)
TARGET_DIRS="app/routers app/services app/utils"

# 自定义技术栈描述 (显示在 AI_MAP.md 头部)
HEADER_TECH_STACK=$(cat <<EOF
- **Framework**: FastAPI
- **Database**: PostgreSQL
- **Architecture**: Domain Driven Design
EOF
)
```

### 第三步：生成/同步地图

运行脚本：

```bash
./bin/sync_guide.sh
```

脚本会：

1.  自动为扫描到的模块目录创建缺少的 `CONTEXT.md` 模板。
2.  提取现有 `CONTEXT.md` 中的职责描述。
3.  生成/更新 `ai-map/AI_MAP.md`。

---

### 第四步：配置 AI 指令 (System Prompt)

将以下规则添加到您的 AI 助手配置中（如 `.cursorrules`, `.gemini/GEMINI.md` 等）。

```markdown
# AI Map / Documentation Strategy

This project uses a tiered documentation system called "AI Map".

1. **Global Map**: `ai-map/AI_MAP.md`.
2. **Local Context**: Each significant directory contains a `CONTEXT.md`.

**Your Mandate:**

- **Read First**: Before editing a module, read its `CONTEXT.md`.
- **Update Always**: If you modify logic, you MUST update its `CONTEXT.md`.
- **Sync**: After updating, run `./bin/sync_guide.sh`.
```

---

### 第五步：部署自动化守门员 (Git Hook)

为了防止开发者（或 AI）忘记更新文档，配置 Git Hook 进行强制校验。

**安装脚本：** `.git/hooks/pre-commit`

```bash
#!/bin/bash
staged_files=$(git diff --cached --name-only)
# 检查修改的代码是否同步更新了对应的 CONTEXT.md
echo "$staged_files" | grep -E "\.(dart|ts|js|go|py)$" | while read -r file; do
    dir=$(dirname "$file")
    while [[ "$dir" != "." && "$dir" != "/" ]]; do
        if [ -f "$dir/CONTEXT.md" ]; then
            if ! echo "$staged_files" | grep -q "^$dir/CONTEXT.md$"; then
                echo "[AI Map] ❌ Missing CONTEXT.md update for: $dir"
                echo "         Please update the documentation to match your code changes."
                exit 1
            fi
            break
        fi
        dir=$(dirname "$dir")
    done
done
```

---

## 核心价值

- **AI 自我修复**：AI 不再只是代码生成器，它成为了自己所需上下文的维护者。
- **强制一致性**：通过 Git Hook 确保文档永不过时。
- **架构主权**：通过 `CONTEXT.md` 明确规定模块职责，防止 AI 在开发时引入跨层调用。
