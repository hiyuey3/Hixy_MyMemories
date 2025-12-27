# MyMemories 项目文档（精简版）

MyMemories 是一个用于记录纪念日/倒数日的 HarmonyOS 应用。本文档概览架构、核心模块、存储方案和常用开发信息，便于快速理解和维护。

## 架构总览
- UI 层：Pages、Components（ArkUI 声明式）
- 状态层：AppStorage + 简易 Store（可选）
- 服务层：MemDBUtils（RDB 封装）
- 数据层：HarmonyOS RDB（本地持久化）

## 核心模块与职责
- Index/HomePage：首页、统计、列表与新增入口
- MemoriesPage：月历视图、日期过滤与跳转
- EditMemory：表单加载与保存
- EventDetail：详情展示、编辑与删除
- ManageMemories：批量导入导出、清理与调试

## 存储与映射
- 表：memories（id, task_name, finished, target_date, content）
- 映射：task_name→title；finished→type（countdown/anniversary）；target_date→date；content→note

## 生命周期与刷新
- 页面：onInit / aboutToAppear / onShow / onDestroy
- 刷新：保存/删除后设置 AppStorage 标记，首页/管理页重载事件列表

## 错误处理与用户反馈
- 外部 API 保留 try/catch（router、pasteboard、vibrator、RDB）
- 用户反馈：Toast、删除确认对话框、振动

## 官方引用（建议替换为准确 URL）
- ArkUI 概览：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-overview
- ArkTS 介绍：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-introduction
- RDB 指南：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-relational-store
- 路由/导航：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/uiability-navigation
- ArkUI 组件：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-components

—— 文档到此为止。保留更多细节请参考 API_REFERENCE.md / DEVELOPER_GUIDE.md。
