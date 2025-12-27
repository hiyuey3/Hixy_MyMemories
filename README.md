# MyMemories (Hixy_MyMemories)

一、移动APP简介
MyMemories 是一款用于记录“倒数日/纪念日/重要日子”的 HarmonyOS 应用（ArkTS + ArkUI）。支持事件新增、编辑、删除、日期计算（剩余/已过天数）、批量导入导出、细腻的卡片式 UI 和基础的用户反馈（Toast、振动）。

二、移动APP功能设计与相关技术
## 2.1 系统总体设计
本系统主要包括如下模块（页面与组件）：
- 用户首页模块（Index + HomePage）：展示头图、统计卡片、事件列表，支持新增入口。
- 记忆列表模块（MemoriesPage）：提供月历视图，支持按日期过滤和跳转指定日期。
- 管理模块（ManageMemories/DeveloperMode）：批量导入导出、清理数据、调试写入、删除确认等。
- 详情模块（EventDetail）：展示事件详情、备注，支持编辑与删除。
- 编辑模块（EditMemory）：表单录入标题、日期、类型与备注，保存到本地数据库。
- 关于模块（About）：展示版本、开发者信息、入口到开发者模式。
- 组件库（EventCard、IndexTabs、BottomTabItem、HomeHeader）：复用展示与导航组件。
- 工具与数据层（dateUtils、MemDBUtils）：日期计算与 RDB 封装。

系统总体功能模块图（示意）如下：
- 首页（Index）
  - 主页内容（HomePage）
    - 统计（Upcoming/Memories）
    - 列表（EventCard）
    - 新增/管理入口
  - Tabs（IndexTabs）
    - 记忆（MemoriesPage：月历过滤）
    - 关于（About）
- 编辑（EditMemory）
- 详情（EventDetail）
- 管理/开发者模式（ManageMemories/DeveloperMode：导入/导出/清理/删除确认）
- 工具（dateUtils：日期计算；MemDBUtils：RDB 读写）

## 2.2 功能详细设计
（1）事件新增/编辑（EditMemory）
- 功能描述：用户进入编辑页，填写标题、选择日期、选择类型（倒数/纪念）、填写备注，点击“保存”提交。若为编辑模式则根据选中 ID 预填原有数据。
- 使用技术或知识点：TextInput、TextArea、DatePicker、Button、Router 导航、RDB 写入（MemDBUtils.insert/update）。

（2）首页展示与统计（Index + HomePage）
- 功能描述：展示头图与两张统计卡片（即将到来的事件数、纪念回顾事件数），下方为事件列表卡片。点击“新增”进入编辑页，点击“管理”进入管理页。
- 使用技术或知识点：组件化（HomePage/EventCard）、Tabs、AppStorage、RDB 查询（MemDBUtils.queryMemories）、dateUtils 天数计算与排序。

（3）记忆列表（月历过滤）（MemoriesPage）
- 功能描述：以月历形式展示可见月份，标注有事件的日期；支持选择日期过滤列表、跳转指定日期、快速返回今日。
- 使用技术或知识点：Builder 渲染网格、日期工具方法（getMonthMatrix/sameDay）、ArkUI 列表与按钮。

（4）事件详情（EventDetail）
- 功能描述：展示标题、日期、类型与备注；支持“编辑”和“删除”操作，删除前弹出确认对话框。
- 使用技术或知识点：Router 参数获取、MemDBUtils 查询与删除、promptAction 弹框、AppStorage 同步刷新。

（5）管理/开发者模式（DeveloperMode）
- 功能描述：导出当前事件为 JSON、复制到剪贴板；导入 JSON 批量写入数据库；调试新增一条测试数据；清理全部数据；删除单条数据带确认与振动反馈。
- 使用技术或知识点：Pasteboard、Vibrator、Toast、RDB 批量写入与删除、JSON 序列化/反序列化、UI 状态控制（@State/@Link）。

三、数据来源
本项目使用 HarmonyOS 本地 RDB 进行数据持久化，由 `MemDBUtils.ets` 封装。核心表结构如下（表：`memories`）：
- 字段与含义：
  - id: integer, 主键自增（主码）
  - task_name: text, 事件标题（非空）
  - finished: boolean/integer, 是否已完成（用于区分倒数/纪念）
  - target_date: number, 目标日期（毫秒时间戳，可选）
  - content: text, 备注（可选）

数据映射到类型：
- MemoryItem: { id: number; title: string; date: Date|number|string|null|undefined; type: 'countdown'|'anniversary'; note?: string }
- 类型转换：task_name -> title；finished -> type（true=anniversary/false=countdown）；target_date -> date；content -> note

如果使用 JSON 数据（导入/导出），文件格式如下：
- 导出 JSON（示例，文本以 `ioText` 文本框呈现，复制到剪贴板）：
```
[
  { "title": "生日", "date": 1735000000000, "type": "countdown" },
  { "title": "纪念日", "date": "2025-10-01", "type": "anniversary" }
]
```
- 导入 JSON（示例）：同上。应用会解析每条记录：
  - title: 字符串，必填
  - type: 'countdown' 或 'anniversary'（缺省为 'countdown'）
  - date: 毫秒、ISO 字符串或空（空将按当前时间或逻辑默认处理）

四、系统成果
请在提交报告时贴出完整的功能截图（建议包含）：
- 首页（头图、统计卡片、事件列表）
- 记忆列表（月历与日期过滤）
- 事件详情（展示与编辑入口、删除确认）
- 编辑页（表单录入与保存成功）
- 管理/开发者模式（导入/导出、清理、删除确认、复制到剪贴板）
- 导入 JSON 样例与导出 JSON 文本

示例流程（4.1 登录模块参考，替换为本系统实际流程）：
- 新增事件：点击“新增”→ 填写表单 → 保存后返回首页并刷新列表。
- 删除事件：在详情或管理页点击“删除”→ 弹出确认 → 删除成功后返回首页并刷新。

五、遇到关键问题与解决方案
- 问题：不同 SDK 版本对 `RdbPredicates.orderByDesc` 的支持差异。
  - 解决：调用处增加 try/catch 容错，不影响查询主流程。
- 问题：UI 主题颜色与暗色模式兼容。
  - 解决：建议逐步将硬编码颜色替换为资源引用（如 `$r('app.color.start_window_background')`），本项目已在部分组件采用资源色。
- 问题：导入 JSON 时日期格式不一。
  - 解决：兼容 number/string，并对非法值回退到当前时间或跳过记录；导出时统一为毫秒或 ISO 字符串。
- 问题：页面刷新与数据一致性。
  - 解决：保存/删除后设置 AppStorage 标记并在首页生命周期钩子中统一重载；管理页在操作后调用 `loadEvents()`。

六、个人收获与反思
- 对 ArkTS + ArkUI 的声明式编程模式有了实践与理解，组件化与状态驱动提升了可读性与维护性。
- RDB 封装与类型映射提升了数据层的清晰度，避免了散落的 SQL 操作。
- 在界面交互上，适度的用户反馈（Toast、振动、确认对话框）有效提升了易用性。
- 后续可以加强：统一主题颜色、增加单元测试（组件与 DB 工具）、完善 MemoryStore 以降低多个页面的耦合。

七、附录
- 文档索引：
  - PROJECT_OVERVIEW.md — 项目概览与结构
  - DOCUMENTATION.md — 架构与模块说明
  - API_REFERENCE.md — 类型与接口参考
  - DEVELOPER_GUIDE.md — 开发与扩展指南
  - USER_GUIDE.md — 使用指南
- 关键文件：
  - `entry/src/main/ets/utils/MemDBUtils.ets` — RDB 封装与 CRUD
  - `entry/src/main/ets/utils/dateUtils.ets` — 日期工具与天数计算
  - `entry/src/main/ets/pages/` — 页面入口与内容
  - `entry/src/main/ets/components/` — UI 组件
- 构建与运行（DevEco Studio 推荐）：打开项目 → 选择设备 → Run；命令行示例：
```bash
cd Hixy_MyMemories/entry
# 具体构建命令以 DevEco 项目配置为准
# 如需安装 .hap 可参考 DevEco 文档
```

> 注：报告中的“系统总体功能图/流程图”可使用 Visor 或任意流程图工具绘制，并将截图贴入结果章节。
