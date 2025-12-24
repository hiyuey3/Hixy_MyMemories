export type MemoryType = 'countdown' | 'anniversary';

export interface MemoryItem {
  id: number;
  title: string;
  date: Date;
  type: MemoryType;
  note?: string;
}

