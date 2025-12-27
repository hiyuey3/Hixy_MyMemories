// 类型定义：事件模型与日期类型 / Type definitions: event model & date types
// 主要职责：统一事件数据结构，便于各模块复用

export type DateLike = Date | number | string | null | undefined;
export type MemoryType = 'countdown' | 'anniversary';

export interface MemoryItem {
  id: number;
  title: string;
  // store date as timestamp (ms) or Date; keep nullable but required property
  date: DateLike;
  type: MemoryType;
  note?: string;
}
