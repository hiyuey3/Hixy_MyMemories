# MyMemories API 参考（精简版）

概览项目中的主要类型与接口，便于快速查阅与开发。

## 类型与数据模型
- MemoryItem：{ id: number; title: string; date: Date|number|string|null|undefined; type: 'countdown'|'anniversary'; note?: string }
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

## 日期工具（dateUtils）
- 位置：`entry/src/main/ets/utils/dateUtils.ets`
- 方法：
  - formatDate(d: DateLike): string — 日期格式化（yyyy-MM-dd）
  - daysDiff(target: DateLike, now?: DateLike, isAnniversary?: boolean): number — 天数差
  - anniversaryStats(target: DateLike, now?: DateLike): { daysSince, daysUntil } — 纪念日统计
  - getEventsSortedByDaysUntil(events: T[], now?: DateLike, isAnniversaryFor?: (e: T) => boolean): T[] — 按天数排序
  - countUpcoming(events: T[], ...): number — 未来事件计数
  - countMemories(events: T[], ...): number — 已过事件计数

## 官方引用（建议替换为准确 URL）
- ArkUI 概览：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-overview
- ArkTS 介绍：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-introduction
- RDB 指南：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-relational-store

更多细节请参考完整源代码与文档：`DEVELOPER_GUIDE.md`、`DOCUMENTATION.md`。
