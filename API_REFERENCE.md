# MyMemories API 参考文档

## 概述

本文档详细介绍了 MyMemories 应用的 API 接口和核心功能模块。包括数据库工具、数据模型、状态管理器等核心组件的详细说明。

## 目录

1. [数据模型](#数据模型)
2. [数据库工具](#数据库工具)
3. [状态管理器](#状态管理器)
4. [页面组件](#页面组件)
5. [类型定义](#类型定义)

## 数据模型

### Memory 类

Memory 类定义了数据库中存储的记忆记录结构。

#### 定义位置
`entry/src/main/ets/utils/MemDBUtils.ets`

#### 属性
- `id: number` - 记忆记录的唯一标识符
- `title: string` - 记忆标题
- `finished: boolean` - 是否为纪念日 (true=纪念日, false=倒数日)
- `content?: string` - 可选的记忆内容
- `createdAt?: number` - 可选的创建时间戳

#### 构造函数
```typescript
constructor(id: number, title: string, finished: boolean, content?: string, createdAt?: number)
```

**参数说明:**
- `id`: 记录ID
- `title`: 记忆标题
- `finished`: 是否完成 (true为纪念日，false为倒数日)
- `content`: 可选内容
- `createdAt`: 可选创建时间戳

## 数据库工具

### MemoryDBUtil

MemoryDBUtil 是数据库操作的工具类，提供了对 HarmonyOS RDB 数据库的封装。

#### 定义位置
`entry/src/main/ets/utils/MemDBUtils.ets`

#### 方法

##### initMemoryDB
初始化数据库连接。

```typescript
initMemoryDB(context: Context, tableName: string): void
```

**参数:**
- `context`: 应用上下文
- `tableName`: 数据库表名

**说明:**
- 创建数据库文件 'hixy.db'
- 设置安全级别为 S1
- 创建 memories 表 (如果不存在)

##### insertMemory
向数据库插入新的记忆记录。

```typescript
async insertMemory(tableName: string, value: relationalStore.ValuesBucket): Promise<number>
```

**参数:**
- `tableName`: 表名
- `value`: ValuesBucket 对象，包含 task_name 和 finished 字段

**返回值:**
- 插入记录的行ID (成功时)
- 抛出错误 (失败时)

**说明:**
- 异步操作
- 插入成功后触发订阅通知
- 返回新记录的自增ID

##### queryMemories
查询数据库中的记忆记录。

```typescript
async queryMemories(tableName: string, column: Array<string>): Promise<Memory[]>
```

**参数:**
- `tableName`: 表名
- `column`: 要查询的列名数组

**返回值:**
- Memory 对象数组 (成功时)
- 空数组 (失败时)

**说明:**
- 按ID降序排列 (最新在前)
- 自动关闭 ResultSet
- 包含异常处理

##### deleteMemoryById
根据ID删除记忆记录。

```typescript
async deleteMemoryById(tableName: string, memoryId: number): Promise<number>
```

**参数:**
- `tableName`: 表名
- `memoryId`: 要删除的记录ID

**返回值:**
- 影响的行数 (成功时)
- 抛出错误 (失败时)

**说明:**
- 异步操作
- 删除成功后触发订阅通知

##### updateMemoryById
根据ID更新记忆记录。

```typescript
async updateMemoryById(tableName: string, memoryId: number, value: relationalStore.ValuesBucket): Promise<number>
```

**参数:**
- `tableName`: 表名
- `memoryId`: 要更新的记录ID
- `value`: ValuesBucket 对象，包含要更新的字段

**返回值:**
- 影响的行数 (成功时)
- 抛出错误 (失败时)

**说明:**
- 异步操作
- 更新成功后触发订阅通知

##### subscribe
订阅数据库变化通知。

```typescript
subscribe(cb: () => void): () => void
```

**参数:**
- `cb`: 变化时的回调函数

**返回值:**
- 取消订阅的函数

## 状态管理器

### MemoryStore

MemoryStore 是应用的状态管理器，负责管理记忆事件列表和提供数据访问接口。

#### 定义位置
`entry/src/main/ets/store/MemoryStore.ets`

#### 接口定义
```typescript
interface MemoryStoreAPI {
  init?(context?: Context): Promise<void>;
  getEvents(): MemoryItem[];
  getEventById(id: number): MemoryItem | undefined;
  addEvent(item: MemoryItem): Promise<void> | void;
  updateEvent(item: MemoryItem): Promise<void> | void;
  deleteEvent(id: number): Promise<void> | void;
  setSelected(id?: number): void;
  getSelected(): number | undefined;
  subscribe(cb: () => void): () => void;
}
```

#### 方法

##### init
初始化 MemoryStore。

```typescript
public async init(context?: Context): Promise<void>
```

**参数:**
- `context`: 可选的应用上下文

**说明:**
- 初始化数据库连接
- 从数据库加载现有数据
- 尝试从本地备份恢复数据

##### getEvents
获取所有记忆事件。

```typescript
public getEvents(): MemoryItem[]
```

**返回值:**
- MemoryItem 对象数组的副本

##### getEventById
根据ID获取特定记忆事件。

```typescript
public getEventById(id: number): MemoryItem | undefined
```

**参数:**
- `id`: 记忆事件ID

**返回值:**
- 找到的记忆事件或 undefined

##### addEvent
添加新的记忆事件。

```typescript
public async addEvent(item: MemoryItem): Promise<void>
```

**参数:**
- `item`: 要添加的记忆事件

**说明:**
- 首先尝试插入数据库
- 如果数据库操作失败，保存到本地备份
- 更新本地事件列表
- 通知所有订阅者

##### updateEvent
更新现有的记忆事件。

```typescript
public async updateEvent(item: MemoryItem): Promise<void>
```

**参数:**
- `item`: 要更新的记忆事件

**说明:**
- 更新数据库中的记录
- 更新本地事件列表
- 通知所有订阅者

##### deleteEvent
删除记忆事件。

```typescript
public async deleteEvent(id: number): Promise<void>
```

**参数:**
- `id`: 要删除的记忆事件ID

**说明:**
- 从数据库删除记录
- 从本地事件列表移除
- 如果是选中项则清除选中状态
- 通知所有订阅者

##### setSelected
设置选中的记忆事件ID。

```typescript
public setSelected(id?: number): void
```

**参数:**
- `id`: 可选的记忆事件ID

##### getSelected
获取选中的记忆事件ID。

```typescript
public getSelected(): number | undefined
```

**返回值:**
- 选中的记忆事件ID或 undefined

##### subscribe
订阅状态变化通知。

```typescript
public subscribe(cb: () => void): () => void
```

**参数:**
- `cb`: 状态变化时的回调函数

**返回值:**
- 取消订阅的函数

## 页面组件

### Index 组件

主页组件，提供应用的主要界面。

#### 定义位置
`entry/src/main/ets/pages/Index.ets`

#### 功能
- 显示记忆列表
- 提供统计信息
- 导航标签页
- 新增记忆功能

#### 主要方法
- `loadEvents()`: 从数据库加载事件
- `daysDiff()`: 计算日期差异
- `sorted()`: 获取按日期排序的事件
- `getUpcoming()`: 获取即将到来的事件数量
- `getMemories()`: 获取已过去的记忆数量

### AddMemory 组件

添加记忆事件的页面组件。

#### 定义位置
`entry/src/main/ets/pages/AddMemory.ets`

#### 功能
- 输入记忆标题
- 选择日期
- 选择记忆类型
- 保存到数据库

#### 主要方法
- `saveAndBack()`: 保存数据并返回

### EditMemory 组件

编辑记忆事件的页面组件。

#### 定义位置
`entry/src/main/ets/pages/EditMemory.ets`

#### 功能
- 加载现有记忆数据
- 编辑记忆信息
- 保存修改

#### 主要方法
- `load(id: number)`: 根据ID加载记忆
- `save()`: 保存修改

### EventDetail 组件

显示记忆详情的页面组件。

#### 定义位置
`entry/src/main/ets/pages/EventDetail.ets`

#### 功能
- 显示记忆详细信息
- 提供编辑功能
- 提供删除功能

#### 主要方法
- `refresh()`: 刷新数据
- `goEdit()`: 跳转到编辑页面
- `doDelete()`: 删除当前事件

### ManageMemories 组件

管理记忆事件的页面组件。

#### 定义位置
`entry/src/main/ets/pages/ManageMemories.ets`

#### 功能
- 显示记忆列表
- 提供编辑功能
- 提供删除确认
- 震动反馈

#### 主要方法
- `loadEvents()`: 加载事件列表
- `onEdit(item: MemoryItem)`: 编辑事件
- `onDelete(id: number)`: 删除事件
- `performDelete()`: 执行删除操作
- `triggerVibration()`: 触发震动

### Settings 组件

应用设置页面组件。

#### 定义位置
`entry/src/main/ets/pages/Settings.ets`

#### 功能
- 通知设置
- 提醒天数设置
- 保存设置

#### 主要方法
- `saveSettings()`: 保存设置
- `resetDefaults()`: 恢复默认设置

### About 组件

关于页面组件。

#### 定义位置
`entry/src/main/ets/pages/About.ets`

#### 功能
- 显示应用信息
- 显示开发者信息
- 显示版本信息

## 类型定义

### MemoryType

记忆类型枚举。

#### 定义位置
`entry/src/main/ets/types/MemoryTypes.ts`

#### 值
- `'countdown'`: 倒数日
- `'anniversary'`: 纪念日

### MemoryItem

记忆项目接口。

#### 定义位置
`entry/src/main/ets/types/MemoryTypes.ts`

#### 属性
- `id: number` - 记忆ID
- `title: string` - 记忆标题
- `date: Date` - 记忆日期
- `type: MemoryType` - 记忆类型
- `note?: string` - 可选备注

## 工具函数

### 日期格式化

在多个组件中使用的日期格式化函数。

```typescript
private formatDate(d: Date): string
```

**功能:**
- 将日期格式化为 'yyyy-mm-dd' 格式

### 天数计算

计算目标日期与今天之间的天数差异。

```typescript
private daysDiff(target: Date): number
```

**功能:**
- 计算日期差异（以天为单位）
- 返回正数表示未来，负数表示过去

## 订阅和通知机制

### 数据库订阅

MemoryDBUtil 提供了数据库变化订阅机制：

```typescript
const unsubscribe = MemoryDBUtil.subscribe(() => {
  // 处理数据库变化
});
```

### 状态订阅

MemoryStore 提供了状态变化订阅机制：

```typescript
const unsubscribe = memoryStore.subscribe(() => {
  // 处理状态变化
});
```

**重要提示:**
- 记得在组件销毁时调用 unsubscribe 函数
- 这些订阅机制确保UI能及时响应数据变化

## 错误处理

### 数据库操作错误
- 所有数据库操作都包含错误处理
- 失败时会显示 Toast 消息
- 某些操作提供本地备份作为安全网

### 用户输入验证
- 添加记忆时验证标题不为空
- 日期选择范围限制
- 类型选择验证

## 权限说明

### 震动权限
- `ohos.permission.VIBRATE`: 用于删除操作的震动反馈
- 需要在应用配置中声明

---

**文档版本**: 1.0  
**最后更新**: 2025-12-26