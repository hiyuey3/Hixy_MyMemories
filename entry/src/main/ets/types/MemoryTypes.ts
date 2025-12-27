export type DateLike = Date | number | string | null | undefined;
export type MemoryType = 'countdown' | 'anniversary';

export interface MemoryItem {
  id: number;
  title: string;
  date: DateLike;
  type: MemoryType;
  note?: string;
}

