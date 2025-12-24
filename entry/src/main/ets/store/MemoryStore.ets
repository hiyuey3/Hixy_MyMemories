import { MemoryType, MemoryItem } from '../types/MemoryTypes';
import { RDBUtils, UserInfo } from '../utils/taskUtils';
import common from '@ohos.app.ability.common';
export type { MemoryType, MemoryItem };

interface MemoryStoreAPI {
  init(context?: common.Context): Promise<void>;
  getEvents(): MemoryItem[];
  getEventById(id: number): MemoryItem | undefined;
  addEvent(item: MemoryItem): Promise<void>;
  updateEvent(item: MemoryItem): Promise<void>;
  deleteEvent(id: number): Promise<void>;
  setSelected(id?: number): void;
  getSelected(): number | undefined;
  subscribe(cb: () => void): () => void;
}

class MemoryStoreClass implements MemoryStoreAPI {
  private listeners: Array<() => void> = [];
  private events: MemoryItem[] = [
    { id: 1, title: '生日', date: new Date('2025-06-18'), type: 'anniversary' },
    { id: 2, title: '假期出发', date: new Date('2025-10-01'), type: 'countdown' },
    { id: 3, title: '相识纪念', date: new Date('2024-12-12'), type: 'anniversary' }
  ];
  private selectedId: number | undefined = undefined;
  private dbReady = false;
  private dbUtils: RDBUtils | null = null;

  private notify() {
    for (const cb of this.listeners) cb();
  }

  private memoryToUserInfo(m: MemoryItem): UserInfo {
    const u: UserInfo = {
      id: m.id,
      nickName: m.title,
      createTime: m.date ? m.date.getTime() : Date.now(),
      memo: m.note || '',
      isSynced: true
    };
    return u;
  }

  private userInfoToMemory(u: UserInfo): MemoryItem {
    return {
      id: u.id || Date.now(),
      title: u.nickName || '',
      date: u.createTime ? new Date(u.createTime) : new Date(),
      type: 'anniversary'
    } as MemoryItem;
  }

  public async init(context?: common.Context) {
    try {
      this.dbUtils = RDBUtils.getInstance(context);
      await this.dbUtils.initRDB();
      this.dbReady = true;
      const users = await this.dbUtils.listUsers();
      if (users && users.length > 0) {
        this.events = users.map(u => this.userInfoToMemory(u));
        this.notify();
      }
    } catch (e) {
      console.warn('初始化 RDB 失败，继续使用内存存储:', e);
    }
  }

  public getEvents(): MemoryItem[] {
    return [...this.events];
  }

  public getEventById(id: number): MemoryItem | undefined {
    return this.events.find(e => e.id === id);
  }

  public async addEvent(item: MemoryItem) {
    if (this.dbReady && this.dbUtils) {
      const user: UserInfo = this.memoryToUserInfo(item);
      try {
        const newId = await this.dbUtils.insertUser(user);
        item.id = newId;
      } catch (e) {
        console.warn('写入数据库失败，继续使用内存缓存:', e);
      }
    }
    this.events = [item, ...this.events];
    this.notify();
  }

  public async updateEvent(item: MemoryItem) {
    if (this.dbReady && this.dbUtils) {
      const user: UserInfo = this.memoryToUserInfo(item);
      try {
        await this.dbUtils.updateUser(user);
      } catch (e) {
        console.warn('更新数据库失败:', e);
      }
    }
    this.events = this.events.map(e => e.id === item.id ? item : e);
    this.notify();
  }

  public async deleteEvent(id: number) {
    if (this.dbReady && this.dbUtils) {
      try {
        await this.dbUtils.deleteUser(id);
      } catch (e) {
        console.warn('删除数据库记录失败:', e);
      }
    }
    this.events = this.events.filter(e => e.id !== id);
    if (this.selectedId === id) this.selectedId = undefined;
    this.notify();
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
