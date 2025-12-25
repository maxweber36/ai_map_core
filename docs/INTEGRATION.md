# AI Map (Codex) 集成指南

本指南介绍如何将 **AI Map** 文档系统移植到任何现有项目中。

---

## 🚀 快速开始 (5 步实现 AI 驱动的文档自动化)

### 第 0 步：AI 辅助初始化 (Bootstrap) - **[推荐]**

如果你在一个现有项目中开始，建议让 AI 助手通过探索代码来为你生成首份地图。**注意：必须要求 AI 遵循下文“第一步”中提供的 Markdown 模板结构。**

> **AI 指令示例：**
> "请深度探索我目前的项目结构和核心代码逻辑，并在 `ai-map/` 目录下为我创建一份 `DEVELOPER_GUIDE.md`。
>
> **要求：**
> 1. **遵循模板**：必须使用以下结构，特别是包含 `MODULE_INDEX` 的占位符：
>    ```markdown
>    # Developer Guide & Architecture Map
>
>    ## 🗺️ Project Navigation
>    <!-- MODULE_INDEX_START -->
>    | Module Path | Responsibility Summary |
>    |---|---|
>    <!-- MODULE_INDEX_END -->
>
>    ## 🏗️ Global Conventions
>    (在此填入你探索到的技术栈、架构模式和编码规范)
>    ```
> 2. **职责填充**：在模块列表中，基于你的理解填入目前主要目录的职责描述。
> 3. **仅限文档**：请仅负责生成这份概览文档，暂不需要创建任何自动化脚本。"

---

### 第一步：搭建基础设施 (Infrastructure)

#### 1. 创建总地图
复制 `templates/ai-map/DEVELOPER_GUIDE.md` 到你的项目根目录下的 `ai-map/` 文件夹。

#### 2. 安装同步工具
复制 `bin/sync_guide.sh` 到你的项目根目录下的 `tool/` 文件夹。
别忘了授权：
```bash
chmod +x tool/sync_guide.sh
```

---

### 第二步：配置 AI 指令 (System Prompt)

将以下规则添加到您的 AI 助手配置中（如 `.cursorrules`, `.gemini/GEMINI.md` 等）。

```markdown
# AI Map / Documentation Strategy
This project uses a tiered documentation system called "AI Map".
1. **Global Map**: `ai-map/DEVELOPER_GUIDE.md`.
2. **Local Context**: Each significant directory contains a `CONTEXT.md`.
**Your Mandate:**
- **Read First**: Before editing a module, read its `CONTEXT.md`.
- **Update Always**: If you modify logic, you MUST update its `CONTEXT.md`.
- **Sync**: After updating, run `./tool/sync_guide.sh`.
```

---

### 第三步：部署自动化守门员 (Git Hook)

复制 `templates/hooks/pre-commit` 到你的 `.git/hooks/` 目录。

```bash
cp templates/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

---

### 第四步：渐进式工作流 (Workflow)

1.  **代码修改**：像往常一样编写代码。
2.  **触发校验**：执行 `git commit`。
3.  **智能拦截**：如果拦截，直接让 AI：“为我更新 [目录名] 的 CONTEXT.md”。
4.  **AI 更新并同步**：AI 完成文档补全和同步。
5.  **顺利提交**：通过。
