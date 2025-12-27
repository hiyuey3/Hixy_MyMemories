# MyMemories 开发者指南（精简版）

面向需要扩展或维护本项目的开发者。保留核心信息，去除冗长细节。

## 模块职责速览
- Pages（Index, HomePage, MemoriesPage, EditMemory, EventDetail, About）— UI 页与导航
- Components（EventCard, IndexTabs, BottomTabItem, HomeHeader）— 复用展示与导航
- Utils（MemDBUtils, dateUtils）— 数据与日期工具层
- Store（MemoryStore, AppStorage）— 状态与订阅（可选实现）

## 技术栈与环境
- ArkTS + ArkUI（声明式 UI）
- HarmonyOS RDB（本地数据库）
- 构建：DevEco Studio / Hvigor CLI

## 数据与映射
- 表：`memories`（id, task_name, finished, target_date, content）
- 映射：task_name→title；finished→type；target_date→date；content→note

## 测试建议
- 单元测试：dateUtils、MemDBUtils 的核心逻辑
- UI 预览：组件 Preview 与 Tabs 切换

## 常见问题与建议
- SDK 差异：orderByDesc 容错
- 主题适配：优先使用资源颜色
- 刷新策略：保存/删除后统一重载

## 官方引用（建议替换为准确 URL）
- ArkUI 概览：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-overview
- ArkTS 介绍：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-introduction
- RDB 指南：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-relational-store
- 路由/导航：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/uiability-navigation
- 振动 API：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-vibrator
- 剪贴板 API：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-pasteboard
- promptAction API：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-promptaction
- ArkUI 组件：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-components
- Hvigor 构建：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hvigor-introduction
- 资源/暗色模式：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/resource-color-and-darkmode
