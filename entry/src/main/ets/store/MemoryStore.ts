type MemoryType = 'countdown' | 'anniversary';
interface MemoryItem {
  id: number;
  title: string;
  date: Date;
  type: MemoryType;
  note?: string;
}

const listeners: Array<() => void> = [];
let events: MemoryItem[] = [
  { id: 1, title: '生日', date: new Date('2025-06-18'), type: 'anniversary' },
  { id: 2, title: '假期出发', date: new Date('2025-10-01'), type: 'countdown' },
  { id: 3, title: '相识纪念', date: new Date('2024-12-12'), type: 'anniversary' },
  { id: 4, title: '相识纪念', date: new Date('2024-12-12'), type: 'countdown' },
  { id: 5, title: '毕业纪念', date: new Date('2026-06-30'), type: 'anniversary' },
  { id: 6, title: '新年倒计时', date: new Date('2025-01-01'), type: 'countdown' },
  { id: 7, title: '结婚纪念日', date: new Date('2025-09-15'), type: 'anniversary' },
];

export default {
  getEvents(): MemoryItem[] {
    return [...events];
  },
  addEvent(item: MemoryItem) {
    events = [item, ...events];
    for (const cb of listeners) cb();
  },
  subscribe(cb: () => void) {
    listeners.push(cb);
    return () => {
      const idx = listeners.indexOf(cb);
      if (idx >= 0) listeners.splice(idx, 1);
    };
  }
};

