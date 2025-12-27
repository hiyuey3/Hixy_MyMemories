# MyMemories (Hixy_MyMemories)

记录“纪念日/倒数日/重要日子”的轻量级 HarmonyOS 应用（ArkTS + ArkUI）。你可以添加生日、纪念日、活动等日期，应用会自动计算“还有几天 / 已经多久”。

## 亮点
- 添加、编辑、删除记忆事件
- 倒数日（未来）与纪念日（过去）清晰区分：蓝/橙标签+天数
- 本地 RDB 存储，启动即加载，操作即更新
- 简洁的卡片式 UI，响应式状态驱动（@State/@Prop/@Link）

## 技术栈
- HarmonyOS ArkTS + ArkUI
- 本地数据库：RDB（封装在 `MemDBUtils`）
- 组件化：`HomePage`、`EventCard`、`ManageMemories` 等

## 目录速览
```
entry/src/main/ets/
├── pages/              // Index, HomePage, ManageMemories, EditMemory, About
├── components/         // EventCard, HomeHeader
├── utils/              // MemDBUtils, dateUtils
├── types/              // MemoryTypes
└── entryability/       // EntryAbility
```

## 快速上手
1) 打开 DevEco Studio，Open 项目根目录，等待索引完成
2) 选择设备，点击 Run，应用启动到首页

或使用命令行：
```bash
cd Hixy_MyMemories/entry
./hvigor build
adb install build/outputs/entry-default-unsigned.hap
adb shell am start -n com.example.mymemories/.MainActivity
```

## 使用体验
- 首页展示头图、统计卡片与列表；支持一键“新增事件”
- 管理页支持编辑、删除（带确认与震动反馈）
- 日期计算更贴近直觉：倒数显示剩余天数；纪念显示“下次周年(累计)”

## 关于页面
- 展示版本、开发团队与联系渠道
- 当前包含：邮箱 hi@xyw.cx、GitHub github.com/hiyuey3、版权与备案

## 已做的改进（简述）
- 精简异常提示，保留必要日志与关键异常处理
- 首页拆分为独立组件 `HomePage`，结构更清晰
- 修复纪念日累计天数与下次周年的计算逻辑
- ArkTS 类型统一与编译规则兼容（移除 no-spread 等问题）
- 核心模块补充双语注释（便于阅读与维护）

## 权限与限制
- 震动需 `ohos.permission.VIBRATE`
- 少量 SDK 差异用 try/catch 兜底（例如部分 `orderByDesc`）

## 路线图
- 为 EventCard 添加单元测试
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
