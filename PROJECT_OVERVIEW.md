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
├── pages/       # 页面（Index, HomePage, ManageMemories, EditMemory, About）
├── components/  # 组件（EventCard 等）
├── utils/       # 工具（MemDBUtils, dateUtils）
├── types/       # 类型定义
└── entryability/# 应用入口
```

## 核心功能
- 记忆事件的新增/编辑/删除
- 倒数日与纪念日的颜色区分与天数计算
- 管理页的批量操作与删除确认

## 技术要点
- ArkTS + ArkUI（声明式）
- 本地 RDB 持久化（MemDBUtils 封装）
- AppStorage 驱动的状态同步

## 构建与运行
```bash
cd Hixy_MyMemories/entry
hvigor build
# 使用 DevEco Studio 运行到模拟器或真机
```

## 联系方式
- 团队：小影团队
- 邮箱：hi@xyw.cx
- GitHub：github.com/hiyuey3
