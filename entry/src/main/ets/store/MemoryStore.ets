import { MemoryType, MemoryItem } from '../types/MemoryTypes';
import { relationalStore } from '@kit.ArkData'
import { MemoryDBUtil, Memory } from '../utils/MemDBUtils';
export type { MemoryType, MemoryItem };

const TABLE_NAME = 'memories'

class MemoryStoreClass {
  private listeners: Array<() => void> = [];
  private events: MemoryItem[] = [
    // 默认数据会在 DB 为空时使用
    { id: 1, title: '生日', date: new Date('2025-06-18'), type: 'anniversary' },
    { id: 2, title: '假期出发', date: new Date('2025-10-01'), type: 'countdown' },
    { id: 3, title: '相识纪念', date: new Date('2024-12-12'), type: 'anniversary' }
  ];
  private selectedId: number | undefined = undefined;

  private notify() {
    for (const cb of this.listeners) {
      try { cb() } catch (err) { console.log(`listener 调用出错: ${err}`) }
    }
  }

  public async init(_context?: Context) {
    // 初始化数据库并加载数据
    try {
      if (_context) {
        MemoryDBUtil.initMemoryDB(_context, TABLE_NAME)
      } else {
        console.log('MemoryStore.init: no context provided, skipping DB init')
      }
       // 查询 DB，若有数据则覆盖内存数据
      const cols = ['id', 'task_name', 'finished']
      const rows: Memory[] = await MemoryDBUtil.queryMemories(TABLE_NAME, cols)
      if (rows && rows.length > 0) {
        this.events = rows.map(r => {
          // 将 DB 的 Memory (id, title, finished) 映射为 MemoryItem
          const id: number = r.id ?? 0
          const title: string = r.title ?? ''
          // 无法从 DB 恢复 date/type，这里使用占位：date 为当前时间，type 根据 finished 推断
          const date = new Date()
          const type: MemoryType = r.finished ? 'anniversary' : 'countdown'
          return { id, title, date, type } as MemoryItem
        })
      }
    } catch (err) {
      console.log(`初始化 MemoryStore 时发生错误: ${err}`)
    }
  }

  public getEvents(): MemoryItem[] {
    return [...this.events];
  }

  public getEventById(id: number): MemoryItem | undefined {
    return this.events.find(e => e.id === id);
  }

  public async addEvent(item: MemoryItem): Promise<void> {
    // 插入到 DB：把 title -> task_name，finished 用 type 进行简单映射
    const finishedVal: number = item.type === 'anniversary' ? 1 : 0
    const vb: relationalStore.ValuesBucket = { task_name: item.title, finished: finishedVal }
    try {
      const rowId: number = await MemoryDBUtil.insertMemory(TABLE_NAME, vb)
      if (rowId && rowId > 0) {
        item.id = rowId
      }
    } catch (err) {
      console.log(`向 DB 插入记忆失败: ${err}`)
      // 仍然继续，将项放入内存以便 UI 立即可见
    }

    // 同步内存并通知
    this.events = [item, ...this.events]
    this.notify()
  }

  public async updateEvent(item: MemoryItem): Promise<void> {
    const finishedVal: number = item.type === 'anniversary' ? 1 : 0
    const vb: relationalStore.ValuesBucket = { task_name: item.title, finished: finishedVal }
    try {
      await MemoryDBUtil.updateMemoryById(TABLE_NAME, item.id, vb)
    } catch (err) {
      console.log(`更新 DB 中记忆失败: ${err}`)
    }

    this.events = this.events.map(e => e.id === item.id ? item : e)
    this.notify()
  }

  public async deleteEvent(id: number): Promise<void> {
    try {
      await MemoryDBUtil.deleteMemoryById(TABLE_NAME, id)
    } catch (err) {
      console.log(`从 DB 删除记忆失败: ${err}`)
    }

    this.events = this.events.filter(e => e.id !== id)
    if (this.selectedId === id) this.selectedId = undefined
    this.notify()
  }

  public setSelected(id?: number) {
    this.selectedId = id;
  }

  public getSelected(): number | undefined {
    return this.selectedId;
  }

  public subscribe(cb: () => void): () => void {
    this.listeners.push(cb);
    return () => {
      const idx = this.listeners.indexOf(cb);
      if (idx >= 0) this.listeners.splice(idx, 1);
    };
  }
}

export default new MemoryStoreClass();
