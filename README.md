# MyMemories (Hixy_MyMemories)

> 轻量级 HarmonyOS 纪念日/倒数日应用，支持事件管理、日期计算、数据导入导出等功能。ArkTS + ArkUI 架构，代码注释详尽，便于二次开发和维护。

## 项目亮点
- 事件新增、编辑、删除，批量管理
- 纪念日与倒数日分色显示，天数自动计算
- 本地 RDB 数据库持久化，启动即加载，操作即刷新
- 组件化设计，核心模块均有详细注释
- 数据导入导出，便于迁移和备份
- 支持振动、Toast、Loading 等用户反馈

## 技术栈
- HarmonyOS ArkTS + ArkUI
- 本地数据库 RDB（MemDBUtils 封装）
- 组件化：HomePage、EventCard、ManageMemories 等

## 目录结构
```
entry/src/main/ets/
├── pages/         # 页面（Index, HomePage, ManageMemories, EditMemory, About）
├── components/    # 组件（EventCard 等）
├── utils/         # 工具（MemDBUtils, dateUtils）
├── types/         # 类型定义（MemoryTypes 等）
└── entryability/  # 应用入口
```

## 快速上手
1. 打开 DevEco Studio，Open 项目根目录，等待索引完成
2. 选择设备，点击 Run，应用启动到首页

或使用命令行：
```bash
cd Hixy_MyMemories/entry
./hvigor build
adb install build/outputs/entry-default-unsigned.hap
adb shell am start -n com.example.mymemories/.MainActivity
```

## 使用体验
- 首页展示头图、统计卡片与列表，支持一键“新增事件”
- 管理页支持编辑、删除（带确认与振动反馈）
- 日期计算更贴近直觉：倒数显示剩余天数，纪念显示“下次周年(累计)”

## 关于页面
- 展示版本、开发团队与联系方式
- 当前包含：邮箱 hi@xyw.cx、GitHub github.com/hiyuey3、版权与备案

## 已做的改进（简述）
- 异常提示精简，保留必要日志与关键异常处理
- 首页拆分为独立组件 HomePage，结构更清晰
- 修复纪念日累计天数与下次周年的计算逻辑
- ArkTS 类型统一与编译规则兼容（移除 no-spread 等问题）
- 核心模块补充双语注释（便于阅读与维护）

## 权限与限制
- 振动需 `ohos.permission.VIBRATE`
- 少量 SDK 差异用 try/catch 兜底（如部分 orderByDesc）

## 路线图
- EventCard 单元测试
- MemDBUtils 增加事务与错误码
- 长操作增加 loading 状态
- 数据导出/导入
- 纪念日提醒通知

## 更多文档
- DOCUMENTATION.md — 架构与设计
- API_REFERENCE.md — 类与函数说明
- USER_GUIDE.md — 用户操作指南
- DEVELOPER_GUIDE.md — 开发扩展指南
- PROJECT_OVERVIEW.md — 文档总览

---

> 所有核心代码均已补充详细注释，见各模块文件顶部与关键函数旁。欢迎二次开发、反馈建议。
