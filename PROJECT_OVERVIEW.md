# MyMemories 项目概览（精简版）

MyMemories（Hixy_MyMemories）是一个基于 HarmonyOS 的纪念日/倒数日管理应用，提供直观的天数显示与简洁的列表管理。

## 文档索引
- DOCUMENTATION.md — 架构与模块
- API_REFERENCE.md — 核心接口
- USER_GUIDE.md — 使用说明
- DEVELOPER_GUIDE.md — 开发指南
- README.md — 项目说明

## 代码结构
```
entry/src/main/ets/
├── pages/       # 页面（Index, HomePage, MemoriesPage, EditMemory, EventDetail, About）
├── components/  # 组件（EventCard 等）
├── utils/       # 工具（MemDBUtils, dateUtils）
├── store/       # 状态（可选实现）
└── entryability/# 应用入口
```

## 核心功能
- 事件新增/编辑/删除
- 倒数日与纪念日的颜色区分与天数计算
- 管理页的批量操作与删除确认
- 导入/导出 JSON（开发者模式）

## 构建与运行
- DevEco Studio：打开项目 → 选择设备 → Run
- CLI 提示：具体命令参考 DevEco 文档与项目配置

## 官方引用（建议替换为准确 URL）
- ArkUI 概览：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-overview
- ArkTS 介绍：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-introduction
- RDB 指南：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-relational-store

## 联系方式
- 团队：小影团队
- 邮箱：hi@xyw.cx
- GitHub：github.com/hiyuey3
