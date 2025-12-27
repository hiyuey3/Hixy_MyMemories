# MyMemories (Hixy_MyMemories) 
================================

日期: 2025-12-27

## 项目概述

MyMemories 是一个用于记录"记忆/纪念日/倒数日"的轻量级 HarmonyOS 应用（ArkTS + ArkUI）。用户可以记录重要的日期事件（生日、纪念日、活动倒数等），应用自动计算并展示距离目标日期的天数或已经过去的天数。

## 核心功能

### 主要功能
1. **记忆管理**: 添加、编辑、删除记忆事件
2. **分类显示**: 
   - **倒数日**: 未来即将发生的事件，显示剩余天数（蓝色）
   - **纪念日**: 过去已发生的事件，显示已过天数（橙色）
3. **智能计算**: 自动计算各类日期的距离与统计
4. **数据持久化**: 使用 HarmonyOS RDB 本地存储
5. **视觉友好**: 清晰的卡片式布局与直观的操作流程

### 技术特点
- **声明式 UI**: 使用 ArkUI 框架，代码简洁易读
- **响应式设计**: 基于 @State/@Prop/@Link 的数据驱动
- **本地 RDB 存储**: 通过 MemDBUtils 封装的数据库操作
- **模块化组件**: HomePage、EventCard、ManageMemories 等高内聚组件
- **双语注释**: 所有核心页面与工具函数均包含中英文注释

## 项目结构

```
entry/src/main/ets/
├── pages/
│   ├── Index.ets             ✓ 首页容器：Tab 切换、数据加载（中英文注释）
│   ├── HomePage.ets          ✓ 首页内容组件：头图、统计、列表（中英文注释）
│   ├── ManageMemories.ets    ✓ 管理页面：增删改操作（中英文注释）
│   ├── EditMemory.ets        ✓ 编辑/新增页面：表单与保存（中英文注释）
│   └── About.ets             —— 关于页面
├── components/
│   ├── EventCard.ets         ✓ 事件卡片组件：展示标题、日期、天数（中英文注释）
│   └── HomeHeader.ets        —— 头部组件
├── utils/
│   ├── MemDBUtils.ets        ✓ 数据库工具：RDB 读写与映射（中英文注释）
│   ├── dateUtils.ets         ✓ 日期工具：格式化与天数计算（中英文注释）
│   └── ...
├── types/
│   └── MemoryTypes.ts        —— 类型定义（MemoryItem, DateLike, etc.）
└── entryability/
    └── EntryAbility.ets      —— 应用入口
```

## 重要改进（Latest Updates）

### 代码质量优化
- ✅ **精简 try/catch 与 toast**: 移除冗余的错误提示，保留关键日志与必要的异常处理
- ✅ **组件拆分**: 首页拆分为 `HomePage` 组件，提高代码可维护性
- ✅ **日期计算修复**: 修复纪念日天数计算（多年前的事件不再显示 ~300 天）
- ✅ **类型安全**: 统一 `MemoryItem.date` 为 `DateLike`，修复所有 ArkTS 编译错误
- ✅ **双语注释**: 为所有核心页面与工具函数添加中英文注释

### 关键修复
| 问题 | 解决方案 |
|------|--------|
| Property 'targetDate' does not exist | 在 Memory 类与 MemDBUtils 中补全 targetDate 字段 |
| Date/DateLike 类型不匹配 | 统一 MemoryItem.date 为 required DateLike |
| 多年前的纪念日显示 ~300 天 | 修复 anniversaryStats 计算逻辑，添加 normalizeDate |
| 新增按钮复用旧数据 | 在 onAdd 时清空 AppStorage selectedId |
| ArkTS no-spread 报错 | 用显式循环替代扩展运算符 |

## 项目文档

本项目包含完整的文档体系：

1. **[DOCUMENTATION.md](./DOCUMENTATION.md)** - 项目详细文档，包含架构、功能说明等
2. **[API_REFERENCE.md](./API_REFERENCE.md)** - API参考文档，详细说明核心类和方法
3. **[USER_GUIDE.md](./USER_GUIDE.md)** - 用户使用指南，帮助用户了解如何使用应用
4. **[DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)** - 开发者指南，详细介绍如何扩展和维护项目
5. **[PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md)** - 项目概览，整合所有文档信息

## 代码改进详情

### 1. 精简异常处理与用户反馈
**改进前**: 充满冗余的 try/catch 和 promptAction.showToast
**改进后**: 
- 移除大部分弹窗提示，保留必要的控制台日志
- 仅在关键操作（数据库、路由）保留异常处理
- 振动反馈保留在删除/取消操作中，增强用户体验

示例（ManageMemories.ets）:
```typescript
// Before: try { promptAction.showToast({ message: '删除失败' }); } catch (e) {}
// After: console.error('删除失败', err);
await MemoryDBUtil.deleteMemoryById('memories', this.deleteTargetId);
```

### 2. 首页模块化拆分
**新增**: `HomePage.ets` 独立组件
- 职责: 处理首页内容（头图、统计卡片、列表、操作按钮）
- 输入: @Prop events、imageSource；@Prop回调 onAdd/onManage
- 输出: 完整的首页 UI 与事件处理

**优势**:
- Index.ets 从 324 行精简为管理 Tab 切换与数据加载
- HomePage 内部自处理日期计算、列表排序等细节
- 提高组件复用性和可测试性

### 3. 日期计算逻辑修复
**问题**: 几年前的纪念日仅显示 ~300 天
**原因**: 未区分 daysSince（累计年数）和 daysUntil（下次周年）

**修复方案** (dateUtils.ets):
```typescript
// normalizeDate: 转换为本地午夜，避免时区及时间偏差
function normalizeDate(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

// anniversaryStats: 分别计算累计与未来
daysSince = Math.floor((today - origin) / dayMs);      // 原点到今天
daysUntil = Math.floor((nextOccur - today) / dayMs);   // 今天到下次周年
```

**输出格式**: `daysUntil(daysSince)` 例: `45(1095)` 表示距下次纪念 45 天，累计 1095 天

### 4. ArkTS 类型系统修复
**问题**: 
- Property 'targetDate' does not exist on type 'Memory'
- Date/DateLike 类型不匹配

**修复清单**:
1. `MemDBUtils.ets` Memory 类新增 targetDate 字段
2. `MemoryTypes.ts` 将 MemoryItem.date 改为 `date: DateLike`（必填但可空）
3. 所有页面在 loadEvents 时将 targetDate (ms) 转换为 DateLike
4. normalizeEvents 为空日期补全为 new Date()

### 5. 新增模式参数隔离
**问题**: 点击"新增"后仍加载上次选中的记录
**解决方案**:
- Index.ets openAddMemory(): AppStorage.Set('selectedId', 0)
- ManageMemories.ets onAdd(): 同样清空 selectedId
- EditMemory.ets aboutToAppear(): 当 selectedId === 0 时重置表单

### 6. ArkTS 编译规则兼容
**问题**: no-spread / no-untyped-obj-literals 错误

**修复**:
- 用显式循环替代对象扩展：`{ ...e, date: e.date ?? new Date() }` → normalizeEvents 显式赋值
- 显式声明 MemoryItem 结构而非对象字面量

### 7. 中英文双语注释
**覆盖文件**:
- `pages/Index.ets`
- `pages/HomePage.ets`
- `pages/ManageMemories.ets`
- `pages/EditMemory.ets`
- `components/EventCard.ets`
- `utils/MemDBUtils.ets`
- `utils/dateUtils.ets`

**注释规范**:
- 文件顶部: 双语功能说明
- 关键函数: 简洁的中英文说明
- 复杂逻辑: 行内注释解释意图

## 快速开始

### 前置要求
- HarmonyOS SDK (API 12+)
- DevEco Studio (latest stable)
- 运行环境: 模拟器或真机（支持 HarmonyOS）

### 构建与运行

#### 方案 1: DevEco Studio（推荐）
1. 打开 DevEco Studio
2. **File** → **Open** → 选择 `Hixy_MyMemories` 根目录
3. 等待项目索引完成（首次约 1-2 分钟）
4. 右上角点击 **Run**，选择目标设备
5. 应用在 15-30 秒后启动至首页

#### 方案 2: 命令行
```bash
cd Hixy_MyMemories/entry

# 编译（生成 HAP）
./hvigor build

# 安装到已连接设备
adb install build/outputs/entry-default-unsigned.hap

# 启动应用
adb shell am start -n com.example.mymemories/.MainActivity
```

## 快速功能验收

### 📋 基础操作测试
- [ ] **启动应用**: 显示首页 Tab（首页/记忆/关于）
- [ ] **首页加载**: 头图正常、统计卡片显示数据、列表渲染
- [ ] **新增事件**: 点击"➕新增事件"，跳转编辑页，表单应为空状态
- [ ] **填写表单**: 标题/类型/日期均可编辑
- [ ] **保存新增**: 点击"保存"，返回首页，列表应包含新增项目

### 🔍 编辑与删除测试
- [ ] **编辑记录**: 管理页点击"✍️"，EditMemory 应加载该记录的标题与日期
- [ ] **修改并保存**: 修改后保存，列表应显示更新内容
- [ ] **删除确认**: 点击"🗑️"，出现内联确认按钮
- [ ] **确认删除**: 点击"✅"记录消失；点击"❌"取消删除

### 📅 日期计算测试
1. **倒数日** (e.g., 2025-12-31)
   - 蓝色标签"倒数"
   - 显示剩余天数

2. **纪念日** (e.g., 2020-01-01，过去日期)
   - 橙色标签"纪念"
   - 格式: `下次周年(累计天数)` 例: `32(1826)` = 距下次纪念 32 天，已过 1826 天

3. **统计验证**
   - "即将到来" = 倒数日总数
   - "纪念回顾" = 纪念日总数

### 🔧 调试快速手册
| 操作 | 预期 | 日志搜索 |
|------|------|---------|
| 点击编辑 | 加载对应记录 | "EditMemory.load" |
| 保存修改 | DB 更新，刷新列表 | "更新记忆成功" |
| 删除记录 | DB 删除，列表刷新 | "删除记忆成功" |
| 新增记录 | 插入 DB，导航到首页 | "insertMemory: inserted rowId" |

**常见问题排查**:
- **编辑页标题为空**: 检查 console 日志中 "EditMemory.load" 是否被调用
- **日期计算错误**: 查看 dateUtils 的 normalizeDate 逻辑是否正确
- **列表加载缓慢**: 监控 MemDBUtils "readyPromise resolved" 日志

## 代码导览

### 数据流程图
```
用户交互
   ↓
Index (Tab & 数据加载)
   ↓ ┌─────────────────┐
   ├→ HomePage (首页内容)
   ├→ ManageMemories (管理页)
   └─→ EditMemory (编辑页)
       ↓
   MemoryDBUtil (CRUD)
       ↓
   HarmonyOS RDB
```

### 文件职责速查表
| 文件 | 职责 | 关键方法 |
|------|------|---------|
| Index.ets | Tab 容器、数据加载 | loadEvents(), sorted() |
| HomePage.ets | 首页内容渲染 | normalizeEvents(), getUpcoming() |
| ManageMemories.ets | 列表、增删改 | loadEvents(), onEdit(), performDelete() |
| EditMemory.ets | 表单、保存 | load(), save() |
| EventCard.ets | 卡片单元展示 | daysTextFor(), daysColorFor() |
| MemDBUtils.ets | RDB CRUD 封装 | queryMemories(), insertMemory(), updateMemoryById() |
| dateUtils.ets | 日期计算 | daysDiff(), anniversaryStats(), formatDate() |
| MemoryTypes.ts | 类型定义 | MemoryItem, DateLike |

## 限制与已知问题

### 权限相关
- 震动功能（vibrator）需声明 `ohos.permission.VIBRATE` 权限
- 真实设备需在 manifest 中申请权限并处理运行时权限

### 框架/工具限制
- `@Entry` struct 导出在 ACE 预览模式可能显示警告（运行时正常）
- 部分 SDK 版本不支持 `orderByDesc`（已在 MemDBUtils 中用 try/catch 保护）

### 设计权衡
- 使用 router params + AppStorage 双写以兼容多种运行时
- 生产环境可考虑统一为 router params 并移除 AppStorage 依赖

## 后续改进方向

- [ ] 提取 EventCard 为独立文件，编写单元测试
- [ ] 在 MemDBUtils 添加事务支持与详细错误码处理
- [ ] 为长操作（保存/删除）加入 loading 状态
- [ ] 添加数据导出/导入功能
- [ ] 支持纪念日提醒通知

## 📚 完整文档

更多信息请见项目文档：
- [DOCUMENTATION.md](./DOCUMENTATION.md) - 详细架构与设计说明
- [API_REFERENCE.md](./API_REFERENCE.md) - 类与函数 API 文档
- [USER_GUIDE.md](./USER_GUIDE.md) - 最终用户操作指南
- [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md) - 开发者扩展指南
- [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) - 文档总览
