# AI Map 初始化 Prompt

> 用于在现有项目中让 AI 助手生成首份 `AI_MAP.md` 概览文档。

---

## 使用方法

将以下 Prompt 复制给 AI 助手：

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
