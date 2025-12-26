# MyMemories 
================================

日期: 2025-12-25

## 项目概述

MyMemories (Hixy_MyMemories) 是一个用于记录"记忆/纪念日/倒数日"的轻量 HarmonyOS 应用（ArkTS + Ark UI）。本应用允许用户记录重要的日期事件，如生日、纪念日、重要事件的倒数日等，并提供直观的界面展示距离这些事件还有多少天或已经过去多少天。

### 课程目标（Learning objectives）
- 理解 ArkTS/Ark UI 中页面间的数据传递方式（router params / AppStorage / 装饰器）。
- 学会用组件化（@Component、@Prop、@Link）重构列表项，提升可维护性。
- 实践数据库读写（RDB via MemDBUtils）和页面生命周期（aboutToAppear/onShow）的正确使用。
- 编写可复现的操作步骤与测试方法，保证修改不引入回归。

## 项目结构概览

（仅列示与作业相关的主要位置）
- entry/src/main/ets/pages/
  - ManageMemories.ets    —— 事件管理页面（列表、删除、跳转编辑）
  - EditMemory.ets       —— 编辑页面（加载指定 id 的记录并保存）
  - AddMemory.ets        —— 新增事件页面（留作参考）
- entry/src/main/ets/utils/
  - MemDBUtils.ets       —— 数据库访问封装（query/insert/update/delete）
- entry/src/main/ets/types/
  - MemoryTypes.ts       —— 类型定义（MemoryItem, MemoryType）
- entry/src/main/ets/store/
  - MemoryStore.ets      —— 应用状态管理器

## 核心功能

### 主要功能
- **记忆管理**: 添加、编辑、删除记忆事件
- **分类显示**: 倒数日（未来事件）和纪念日（过去事件）分类管理
- **智能计算**: 自动计算距离目标日期的天数
- **数据持久化**: 使用 HarmonyOS RDB 存储数据
- **直观界面**: 清晰的视觉层次和操作流程

### 技术特点
- **声明式UI**: 使用ArkUI框架，代码简洁易读
- **数据驱动**: 基于状态管理的响应式设计
- **本地存储**: 使用HarmonyOS RDB进行数据持久化
- **组件化**: 高度模块化的组件设计

## 项目文档

本项目包含完整的文档体系：

1. **[DOCUMENTATION.md](./DOCUMENTATION.md)** - 项目详细文档，包含架构、功能说明等
2. **[API_REFERENCE.md](./API_REFERENCE.md)** - API参考文档，详细说明核心类和方法
3. **[USER_GUIDE.md](./USER_GUIDE.md)** - 用户使用指南，帮助用户了解如何使用应用
4. **[DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)** - 开发者指南，详细介绍如何扩展和维护项目
5. **[PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md)** - 项目概览，整合所有文档信息

## 关键实现点（What the app does）
- 列表从本地 RDB 中读取事件并渲染。
- 列表提供编辑与删除操作：编辑会跳转到 `EditMemory` 页面以加载并编辑指定记录；删除提供内联确认。
- 编辑页面可对指定记录进行更新或在不存在时插入新记录。

## 我所做的修改（改进点，What I changed）

### 主要改动文件（摘要）
- `entry/src/main/ets/pages/EditMemory.ets`
  - 使用 `@StorageProp('selectedId') selectedId` 作为 AppStorage 的绑定（装饰器），并在 aboutToAppear 中优先读取 router params（router.getParams()）再回退到 `selectedId`，从而保证能在多种环境下拿到要编辑的 id。
  - 移除了对 AppStorage 的零碎轮询读取逻辑，改为更可靠的优先级读取（router params -> AppStorage）。
  - 保存逻辑保持原样，但移除了对 AppStorage 的在 save 中的额外回退读取（现在由 aboutToAppear 保证 memoryId 已设置）。

- `entry/src/main/ets/pages/ManageMemories.ets`
  - 将每个列表项抽成 `EventCard` 组件（同文件底部新增 @Component struct EventCard），并用 `@Prop` 传入 item，用 `@Link` 链接父页面的 deleteTargetId（以响应内联删除确认状态）。
  - 在触发编辑时，既设置 `AppStorage.selectedId`（兼容旧逻辑/环境），也通过 router params 传递 `editId` 以确保目标页面能尽快获取 id。
  - 将列表中文本的对齐方式调整为左对齐（Column().alignItems(HorizontalAlign.Start)），修复了你提到的"Text(item.title) 不能左对齐"的问题。

## 为什么这样改
- router params 在页面跳转时通常是最直接和确定的传递方式，但不同运行时/预览模式 AppStorage 也有使用场景。将二者结合能兼顾稳定性和兼容性。
- 把复杂的行内逻辑抽成 `EventCard` 组件能降低 `ManageMemories` 页面体积、提高可读性，并能在组件内单独处理震动/确认/回调等副作用。
- 使用 `@Prop` / `@Link` / `@StorageProp` 等装饰器更符合 ArkTS 的声明式风格，便于静态分析与维护。

## 如何运行（Development / Run）
以下步骤基于你使用 DevEco Studio 或命令行构建 HarmonyOS ArkTS 项目的常见流程：

1) 打开项目：在 DevEco Studio 中以现有项目方式打开 `Hixy_MyMemories/entry`。

2) 安装依赖与构建（命令行示例）：

```bash
# 进入 entry 模块
cd /path/to/Hixy_MyMemories/entry
# 使用 hvigor 或 DevEco Studio 的构建流程
# 下面为示例命令（视项目配置而定）
hvigor build
# 或者使用 DevEco Studio 的构建按钮
```

3) 在模拟器或真机上运行：使用 DevEco Studio 的 Run 配置或将生成的 hap 安装到设备上。

4) 打开"管理记忆"页面，点击某条记录的"✍️"进入编辑页，确认标题加载并能保存。

## 测试（快速验收测试清单）
- 编辑传参测试（主要修复点）
  - 在 `ManageMemories` 中点击某条记录的编辑按钮。
  - 检查 `EditMemory` 是否弹出并加载该记录标题（若未加载，检查日志中关于 router.getParams()/AppStorage 的输出）。
  - 修改标题并点击保存，返回列表后该记录应显示修改后的标题。

- 新增/保存回退逻辑
  - 在编辑页清空标题并尝试保存，应提示"标题不能为空"。
  - 如果原记录被删除（edge case），保存应作为新记录插入并返回新的 id。

- 列表对齐
  - 列表项标题必须左对齐（视觉上靠近左侧切线），并且日期在标题下方显示。

## 变更验证方法（运行时日志）
- 编辑页 `EditMemory.load` 含多处 console.log，会打印请求 id、查询返回的行数与找到的记录。遇到问题请查看运行日志（DevEco Studio Logcat / console）。

## 设计权衡与未处理问题（Limitations）
- 震动调用（vibrator.vibrate）在部分环境需要额外权限（ohos.permission.VIBRATE），当前代码在调用处已用 try/catch 包裹，但真实设备上需在 manifest 中添加权限声明并申请运行时权限（若目标系统要求）。
- `@Entry` 以 struct 导出的形式在 ACE 预览模式可能产生警告（IDE 提示），但运行时通常可用；若你需要通过 ACE 组件预览，请考虑示例导出替代形式。
- 路由与 AppStorage 的双写是为了兼容多种运行时；在洁净的生产代码中可统一使用路由 params 并移除 AppStorage 写入。

## 主要改动清单（文件/位置）
- Modified: `entry/src/main/ets/pages/EditMemory.ets`
  - aboutToAppear()：优先 router params，回退 AppStorage via @StorageProp
  - remove redundant AppStorage polling logic
- Modified: `entry/src/main/ets/pages/ManageMemories.ets`
  - Add: `EventCard` component at bottom of file (uses @Prop/@Link)
  - Use AppStorage.setOrCreate('selectedId', id) + router.push(params: { editId }) when editing
  - Adjust layout to left-align title text

## 后续改进建议（Next steps）
- 将 `EventCard` 提取到单独文件并为其编写单元测试（若使用 ArkTS 测试框架/模拟支持）。
- 在 `MemDBUtils` 中增加事务封装与更详细的错误码处理，减少 UI 层对 DB 逻辑的猜测。
- 在保存/删除接口中加入更明确的用户提示与 loading 状态，避免重复点击导致的数据问题。
- 为 vibrator 功能添加权限说明并在 manifest/应用配置中声明对应权限（若需要）。

## 附录：快速定位与调试建议
- 日志关键点：
  - EditMemory.load: 会打印请求 id 与查询结果（search for "EditMemory.load" in logs）
  - EditMemory.save: 会打印保存后的行影响数与 post-save probe
  - ManageMemories.testWrite: 写入测试行并打印 DB 行数

- 常见问题排查：
  - 若 EditMemory 页面一直提示"无法保存：未指定记录"或标题为空，检查 ManageMemories 的 onEdit 是否成功执行（在控制台输出或尝试加一个 promptAction.showToast 调试）。
  - 若列表标题偏移或对齐问题，检查 `Column().alignItems(HorizontalAlign.Start)` 是否在你当前分支/版本中被保留。

## 致谢
本报告由代码辅助修改并生成，变更遵循 ArkTS 的声明式风格与尽量使用原生 API 的原则。如果你希望我把 `EventCard` 单独拆成文件、或把 EditMemory 的参数契约改为仅使用 router params（并移除 AppStorage 相关回退），可以回复我我会继续修改并补上小型单元测试与 README 中的运行命令示例。

## 项目文档
更多详细信息请参见项目文档：
- [DOCUMENTATION.md](./DOCUMENTATION.md) - 项目详细文档
- [API_REFERENCE.md](./API_REFERENCE.md) - API参考文档
- [USER_GUIDE.md](./USER_GUIDE.md) - 用户使用指南
- [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md) - 开发者指南
- [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) - 项目概览