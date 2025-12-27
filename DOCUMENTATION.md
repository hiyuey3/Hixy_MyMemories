# MyMemories 项目文档（精简版）

MyMemories 是一个用于记录纪念日/倒数日的 HarmonyOS 应用。本文档概览架构、核心模块、存储方案和常用开发信息，便于快速理解和维护。

## 架构一览
- UI 层：Pages、Components（ArkUI 声明式）
- 状态层：AppStorage + 简单 Store
- 服务层：MemDBUtils（RDB 封装）
- 数据层：HarmonyOS RDB（本地持久化）

目录重点：
- `entry/src/main/ets/pages/` — 页面（Index, HomePage, ManageMemories, EditMemory, About）
- `entry/src/main/ets/components/` — 组件（EventCard 等）
- `entry/src/main/ets/utils/` — 工具（MemDBUtils, dateUtils）
- `entry/src/main/ets/types/` — 类型（MemoryTypes）

## 核心模块
- Index/HomePage：主页与统计、列表与新增入口
- ManageMemories：批量管理、编辑、删除（带确认/震动反馈）
- EditMemory：表单加载与保存
- EventCard：记忆卡片展示（倒数/纪念样式）
- MemDBUtils：RDB 初始化、CRUD、订阅通知

## 存储与数据映射
- 表：memories（id, task_name, finished）
- 映射：task_name -> MemoryItem.title；finished -> type（countdown/anniversary）
- 订阅：数据库变更可触发 UI 刷新

## 生命周期与同步
- 页面：onInit / aboutToAppear / onDestroy
- 同步策略：页面显示时同步；操作后轻量刷新；订阅驱动 UI 更新

## 错误处理与反馈
- 关键操作保留 try/catch；控制台日志记录
- 用户反馈：必要时 toast；删除类操作提供震动反馈

## 构建与部署
- 构建：hvigor（DevEco Studio 或命令行）
- 运行：模拟器/真机均可；.hap 输出位于 entry/build/outputs/

## 约定与风格
- 组件命名使用 PascalCase；方法/状态使用 camelCase
- 最小化状态；避免直接修改对象；优先可读性

## 后续方向（简述）
- 测试增强（EventCard、MemDBUtils）
- 长操作 Loading 状态与错误码
- 数据导出/导入，提醒通知
- 主题色/暗色模式优化

—— 文档到此为止。保留更多细节请参考 API_REFERENCE.md / DEVELOPER_GUIDE.md。
