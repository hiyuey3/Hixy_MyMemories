import { MemoryType, MemoryItem } from '../types/MemoryTypes';
import { relationalStore } from '@kit.ArkData';
import { MemoryDBUtil, Memory } from '../utils/MemDBUtils';
import promptAction from '@ohos.promptAction';
export type { MemoryType, MemoryItem };
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

class MemoryStoreClass implements MemoryStoreAPI {
  private readonly TABLE_NAME: string = 'memories';
  private listeners: Array<() => void> = [];
  private events: MemoryItem[] = [
    { id: 1, title: '生日', date: new Date('2025-06-18'), type: 'anniversary' },
    { id: 2, title: '假期出发', date: new Date('2025-10-01'), type: 'countdown' },
    { id: 3, title: '相识纪念', date: new Date('2024-12-12'), type: 'anniversary' }
  ];
  private selectedId: number | undefined = undefined;

  // Helper: reload all events from DB into this.events and notify listeners
  private async reloadFromDB(): Promise<void> {
    try {
      const cols: string[] = ['id', 'task_name', 'finished'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories(this.TABLE_NAME, cols);
      if (rows && rows.length > 0) {
        this.events = rows.map((r: Memory) => {
          const id: number = r.id ?? 0;
          const title: string = r.title ?? '';
          const date: Date = new Date();
          const type: MemoryType = r.finished ? 'anniversary' : 'countdown';
          return { id, title, date, type } as MemoryItem;
        });
      } else {
        this.events = [];
      }
      this.notify();
    } catch (e) {
      console.log('reloadFromDB failed', e);
    }
  }

  private notify(): void {
    for (const cb of this.listeners) {
      try { cb(); } catch (err) { console.log(`listener 调用出错: ${err}`); }
    }
  }

  public async init(context?: Context): Promise<void> {
    try {
      if (context) {
        MemoryDBUtil.initMemoryDB(context, this.TABLE_NAME);
      } else {
        console.log('MemoryStore.init: no context provided, skipping DB init');
      }

      const cols: string[] = ['id', 'task_name', 'finished'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories(this.TABLE_NAME, cols);
      if (rows && rows.length > 0) {
        this.events = rows.map((r: Memory) => {
          const id: number = r.id ?? 0;
          const title: string = r.title ?? '';
          const date: Date = new Date();
          const type: MemoryType = r.finished ? 'anniversary' : 'countdown';
          return { id, title, date, type } as MemoryItem;
        });
      } else {
        try {
          const backupJson = AppStorage.Get<string>('mem_backup');
          if (backupJson) {
            const backups = JSON.parse(backupJson as string) as MemoryItem[];
            if (backups && backups.length > 0) {
              this.events = [...backups, ...this.events];
            }
          }
        } catch (e) {
          console.log('MemoryStore.init: 合并本地备份失败', e);
        }
      }
    } catch (err) {
      console.log(`初始化 MemoryStore 时发生错误: ${err}`);
    }
  }

  public getEvents(): MemoryItem[] {
    return [...this.events];
  }

  public getEventById(id: number): MemoryItem | undefined {
    return this.events.find((e: MemoryItem) => e.id === id);
  }

  public async addEvent(item: MemoryItem): Promise<void> {
    const finishedVal: number = item.type === 'anniversary' ? 1 : 0;
    const vb: relationalStore.ValuesBucket = { task_name: item.title, finished: finishedVal } as relationalStore.ValuesBucket;

    try {
      const rowId: number = await MemoryDBUtil.insertMemory(this.TABLE_NAME, vb);
      if (rowId && rowId > 0) {
        item.id = rowId;
        // Prepend and notify only on DB success
        this.events = [item, ...this.events];
        this.notify();
        return;
      }
      // fall through to backup on unexpected rowId
      throw new Error('insert returned invalid rowId')
    } catch (err) {
      console.log(`向 DB 插入记忆失败: ${err}`);
      // Fallback: save to local backup so user data isn't lost
      try {
        const existing = AppStorage.Get<string>('mem_backup');
        const arr: MemoryItem[] = existing ? JSON.parse(existing as string) : [];
        arr.unshift(item);
        AppStorage.Set<string>('mem_backup', JSON.stringify(arr));
        console.log('已保存到本地备份 mem_backup');
      } catch (e) {
        console.log('保存到本地备份失败', e);
      }
      try { promptAction.showToast({ message: '保存失败，已保存为本地备份' }); } catch (_) {}
      // attempt to reload DB to keep UI consistent
      await this.reloadFromDB();
    }
  }

  public async updateEvent(item: MemoryItem): Promise<void> {
    const finishedVal: number = item.type === 'anniversary' ? 1 : 0;
    const vb: relationalStore.ValuesBucket = { task_name: item.title, finished: finishedVal } as relationalStore.ValuesBucket;
    try {
      const rows: number = await MemoryDBUtil.updateMemoryById(this.TABLE_NAME, item.id, vb);
      if (rows > 0) {
        this.events = this.events.map((e: MemoryItem) => (e.id === item.id ? item : e));
        this.notify();
      } else {
        try { promptAction.showToast({ message: '更新失败：无记录被修改' }); } catch (_) {}
        await this.reloadFromDB();
      }
    } catch (err) {
      console.log(`更新 DB 中记忆失败: ${err}`);
      try { promptAction.showToast({ message: '更新失败' }); } catch (_) {}
      await this.reloadFromDB();
    }
  }

  public async deleteEvent(id: number): Promise<void> {
    try {
      const rows: number = await MemoryDBUtil.deleteMemoryById(this.TABLE_NAME, id);
      if (rows > 0) {
        this.events = this.events.filter((e: MemoryItem) => e.id !== id);
        if (this.selectedId === id) this.selectedId = undefined;
        this.notify();
        return;
      }
      try { promptAction.showToast({ message: '删除失败：未影响任何行' }); } catch (_) {}
      await this.reloadFromDB();
    } catch (err) {
      console.log(`从 DB 删除记忆失败: ${err}`);
      try { promptAction.showToast({ message: '删除失败' }); } catch (_) {}
      await this.reloadFromDB();
    }
  }

  public setSelected(id?: number): void {
    this.selectedId = id;
  }

  public getSelected(): number | undefined {
    return this.selectedId;
  }

  public subscribe(cb: () => void): () => void {
    this.listeners.push(cb);
    return (): void => {
      const idx = this.listeners.indexOf(cb);
      if (idx >= 0) this.listeners.splice(idx, 1);
    };
  }
}

export default new MemoryStoreClass();
