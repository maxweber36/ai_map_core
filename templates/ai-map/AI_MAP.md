# AI MAP

> **AI 与开发者必读**
> 本文档是项目的“宪法”。它定义了项目的核心架构、开发规范和模块地图。
> **注意：** 下方的“模块索引”由脚本自动生成。请修改各模块目录下的 CONTEXT.md，然后运行 bin/ai_map.sh --sync 同步。

## 全局架构规范 (Global Architecture)

- **核心框架**: Flutter
- **状态管理**: Riverpod 2.x
- **路由管理**: GoRouter
- **本地存储**: Isar Database
- **设计风格**: Material 3 / Pixel Art

## 开发准则 (Principles)

1. **单一职责**: 每个模块应通过 CONTEXT.md 明确其职责边界。
2. **解耦原则**: 模块间应避免强耦合，遵循依赖倒置。
3. **接口优先**: 修改模块前，先阅读并更新其 CONTEXT.md 中的接口章节。

## 模块索引 (Module Index)

| 模块路径              | 职责摘要                                                                     | 详细上下文                                        |
| :-------------------- | :--------------------------------------------------------------------------- | :------------------------------------------------ |
| lib/features/auth     | 负责用户身份验证流程，包括邮箱登录、访客模式、登录状态持久化及路由权限守卫。 | [查看上下文](../lib/features/auth/CONTEXT.md)     |
| lib/features/home     | 核心计时器界面，负责语音输入识别、任务创建以及实时计时展示。                 | [查看上下文](../lib/features/home/CONTEXT.md)     |
| lib/features/history  | 展示历史任务记录，提供按时间维度的查询、筛选以及 CSV 导出功能。              | [查看上下文](../lib/features/history/CONTEXT.md)  |
| lib/features/settings | 管理应用全局配置、用户账户状态以及特定数据管理（子类别、日志）。             | [查看上下文](../lib/features/settings/CONTEXT.md) |

---

_Last synced: Thu Dec 25 07:31:55 CST 2025_
