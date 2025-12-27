# MyMemories API 参考（精简版）

概览项目中的主要类型与接口，便于快速查阅与开发。

## 类型与数据模型
- MemoryItem：{ id: number; title: string; date: Date; type: 'countdown' | 'anniversary'; note? }
- MemoryType：'countdown' | 'anniversary'

## 数据库工具（MemDBUtils）
- 位置：`entry/src/main/ets/utils/MemDBUtils.ets`
- 方法：
  - initMemoryDB(context: Context, tableName: string): void — 初始化数据库
  - insertMemory(tableName: string, value: relationalStore.ValuesBucket): Promise<number> — 插入记录
  - queryMemories(tableName: string, column: string[]): Promise<Memory[]> — 查询记录
  - deleteMemoryById(tableName: string, memoryId: number): Promise<number> — 删除记录
  - updateMemoryById(tableName: string, memoryId: number, value: relationalStore.ValuesBucket): Promise<number> — 更新记录
  - subscribe(cb: () => void): () => void — 订阅变化

## 状态管理（MemoryStore）
- 位置：`entry/src/main/ets/store/MemoryStore.ets`
- 接口：
  - init(context?: Context): Promise<void>
  - getEvents(): MemoryItem[]
  - getEventById(id: number): MemoryItem | undefined
  - addEvent(item: MemoryItem): Promise<void>
  - updateEvent(item: MemoryItem): Promise<void>
  - deleteEvent(id: number): Promise<void>
  - setSelected(id?: number): void
  - getSelected(): number | undefined
  - subscribe(cb: () => void): () => void

## 页面组件
- 位置：`entry/src/main/ets/pages/`
- Index：主页，加载事件、统计与导航
- HomePage：首页呈现与布局
- ManageMemories：列表、编辑、删除、震动反馈
- EditMemory：表单加载与保存
- EventDetail：详情、编辑、删除
- About：关于与联系渠道

## 约定与建议
- 所有数据库操作为异步，注意错误处理与用户反馈
- 使用订阅/状态驱动 UI 刷新
- 颜色尽量使用主题/分层参数，减少硬编码

更多细节请参考完整源代码与文档：`DEVELOPER_GUIDE.md`、`DOCUMENTATION.md`。
