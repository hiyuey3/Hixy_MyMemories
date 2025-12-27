# MyMemories 开发者指南（精简版）

面向需要扩展或维护本项目的开发者。保留核心信息，去除冗长细节。

## 技术栈与环境
- ArkTS + ArkUI（声明式 UI）
- HarmonyOS RDB（本地数据库）
- 状态：AppStorage + 简易 Store
- 构建：Hvigor（DevEco Studio / CLI）

## 分层架构
- UI：Pages/Components（entry/src/main/ets/pages, components）
- 状态：MemoryStore, AppStorage（entry/src/main/ets/store）
- 服务：MemDBUtils（entry/src/main/ets/utils）
- 数据：HarmonyOS RDB

## 关键模块
- Index/HomePage：主界面与导航
- ManageMemories：列表、编辑、删除、确认
- EditMemory：加载/保存表单
- EventCard：卡片展示与样式
- MemDBUtils：RDB 初始化、CRUD、订阅

## 代码约定
- 组件用 PascalCase；方法/变量 camelCase
- 最小化状态；避免直接修改对象；类型明确
- 注释简洁，函数签名清晰

## 构建与运行
```bash
cd Hixy_MyMemories/entry
hvigor build
# 建议使用 DevEco Studio 运行到模拟器/真机
```

## 测试
- 位置：`entry/src/ohosTest/` 与 `entry/src/test/`
- 覆盖：工具函数、业务逻辑、基本交互
- 目标：事件 CRUD、日期计算、订阅通知

## 扩展与优化建议
- 为 MemDBUtils 增加事务与错误码
- 重要操作增加 loading 与用户提示
- 统一主题色/暗色模式；替换硬编码颜色
- 增加导入/导出与提醒通知

## 常见问题
- 页面未刷新：检查订阅与 AppStorage 绑定
- 列表为空：确认 RDB 初始化与表是否存在
- 编译告警：颜色使用主题/分层参数替代十六进制

更多细节请参考：`API_REFERENCE.md` 与 `DOCUMENTATION.md`。
