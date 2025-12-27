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
