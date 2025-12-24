type MemoryType = 'countdown' | 'anniversary';
export interface MemoryItem {
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
  { id: 3, title: '相识纪念', date: new Date('2024-12-12'), type: 'anniversary' }
];
let selectedId: number | undefined = undefined;

function notify() {
  for (const cb of listeners) cb();
}

export default {
  getEvents(): MemoryItem[] {
    return [...events];
  },
  getEventById(id: number): MemoryItem | undefined {
    return events.find(e => e.id === id);
  },
  addEvent(item: MemoryItem) {
    events = [item, ...events];
    notify();
  },
  updateEvent(item: MemoryItem) {
    events = events.map(e => e.id === item.id ? item : e);
    notify();
  },
  deleteEvent(id: number) {
    events = events.filter(e => e.id !== id);
    if (selectedId === id) selectedId = undefined;
    notify();
  },
  setSelected(id?: number) {
    selectedId = id;
  },
  getSelected(): number | undefined {
    return selectedId;
  },
  subscribe(cb: () => void) {
    listeners.push(cb);
    return () => {
      const idx = listeners.indexOf(cb);
      if (idx >= 0) listeners.splice(idx, 1);
    };
  }
};
