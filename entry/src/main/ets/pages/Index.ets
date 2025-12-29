// 首页容器：负责 Tab 切换与数据加载
// 主要职责：初始化数据库、加载事件列表、处理 Tab 切换与页面刷新
// 事件数据通过 MemoryDBUtil 查询，映射为 MemoryItem 供 UI 展示

import { MemoryDBUtil, Memory } from '../utils/MemDBUtils';
import * as dateUtils from '../utils/dateUtils';
import router from '@system.router';
import { IndexTabs } from '../components/IndexTabs';
import { MemoryItem, MemoryType } from '../types/MemoryTypes';


@Entry
@Component
struct Index {
  // events loaded from DB via MemoryDBUtil
  @State events: MemoryItem[] = [];
  @State currentIndex: number = 0;
  @State selectedDate: Date | null = null;
  @State visibleMonth: Date = new Date();
  // @State addFeedback: string = '';
  // Persisted header image uri
  @State headerImagePath: string = '';

  // 页面加载与切换逻辑说明（注释版）：
  // - onInit(): 组件被创建并初始化时调用一次。
  // 用于执行一次性的初始化，例如加载持久化头图与首次从数据库读取事件。
  // - aboutToAppear(): 页面即将可见时调用（比 onShow 更靠前），
  // 这里代码会强制重新查询数据库并启动短延迟的二次查询，目的是尽可能保证在慢设备上也能看到刚写入的数据。
  // - onShow(): 页面每次变为可见时调用（例如从其他页面返回），会再次触发加载；
  // 同时会检查 AppStorage 的 'needsReload' 标志以决定是否需要额外刷新。
  // - build() 中传入的 IndexTabs 回调（onReloadHome/onAdd/onTabChange）：用户交互也会触发加载，例如用户点刷新或新增记忆后需要重新加载数据。
  // - 数据刷新策略说明：当前实现采用多点触发（生命周期 + needsReload flag + 延迟二次刷新 + 手动刷新回调）


  onInit(): void {
    // 初始化数据库并加载事件（只在组件创建时执行一次）
    this.loadHeaderImage();
    this.loadEvents();
  }

  onShow(): void {
    // 每次页面显示时重新加载事件（确保从其它页面返回后数据是最新的）
    this.loadEvents();
    // 使用 AppStorage 的 needsReload 作为跨页面的简单通知：如果其它页面在写入后设置了该标志，这里会在显示时再次刷新并清除标志。
    // 注意：该机制是弱通知（非实时），写入方必须显式设置标志；多个页面写同一 flag 可能导致时序不确定。
    const reload = AppStorage.Get<boolean>('needsReload');
    if (reload) {
      this.loadEvents();
      AppStorage.Set<boolean>('needsReload', false);
    }
  }

  aboutToAppear(): void {
    // 页面即将显示时强制重新查询数据库（触发更靠前的刷新，覆盖可能的 stale UI）
    this.loadEvents();
    // 小延迟刷新（300ms）是一个保护性手段，用于在某些设备/环境下确保能读到刚提交的数据库记录；该策略会增加重复加载的概率。
    try { setTimeout(() => this.loadEvents(), 300); } catch (e) {}
    // 同样检查 needsReload 标志（与 onShow 类似）
    const reload = AppStorage.Get<boolean>('needsReload');
    if (reload) {
      this.loadEvents();
      AppStorage.Set<boolean>('needsReload', false);
    }
  }

  onDestroy(): void {}

  // 页面结构
  build() {
    Column() {
      // IndexTabs 组件渲染：
      // - 这是页面的子组件（Tab 视图），放在当前组件树中，框架会在 build() 被调用时把它渲染到屏幕上，
      // - 组件通过 props 接收数据（events, sortedEvents, imageSource 等），这些数据由当前页面的状态提供（this.events 等）
      //   所以页面显示的内容是由上层组件的生命周期（onInit/onShow/aboutToAppear）通过 loadEvents 填充的。
      // - IndexTabs 同时暴露回调（onTabChange/onAdd/onReloadHome）
      // 调用这些回调把事件传回给父组件，父组件再执行如 router.push 或 loadEvents 等动作。
      // - （1）框架挂载 Entry 组件并触发生命周期（onInit/onShow 等），
      //   （2）父组件在生命周期中加载数据并设置 state，渲染时把数据传给 IndexTabs，
      //   （3）IndexTabs 渲染 UI 并通过回调把用户操作传回父组件处理。
      IndexTabs({
        events: this.events,
        sortedEvents: this.sorted(),
        currentIndex: this.currentIndex,
        imageSource: this.imageSource(),
        onTabChange: (idx: number) => {
          // 标签切换仅更新索引，UI 会根据 this.currentIndex 渲染不同的内容
          this.currentIndex = idx;
        },
        onAdd: () => this.openAddMemory(),
        onReloadHome: () => {
          // 用户手动触发的刷新：立即刷新并在 300ms 后再做一次短延迟刷新（与 aboutToAppear 相同的防护性策略）
          this.loadEvents();
          setTimeout(() => this.loadEvents(), 300);
        }
      });
    }
    .width('100%')
    .height('100%');
  }

  // 从持久化存储加载头部图片路径（如果存在）
  private loadHeaderImage(): void {
    const stored = AppStorage.Get<string>('headerImagePath');
    this.headerImagePath = stored ?? '';
  }

  // 从数据库加载事件并映射为 MemoryItem[]
  private async loadEvents(): Promise<void> {
    try {
      // 查询数据库并组装渲染数据
      const cols = ['id', 'task_name', 'finished', 'target_date'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      if (rows && rows.length > 0) {
        const mapped: MemoryItem[] = rows.map((r: Memory): MemoryItem => {
          // 注意：r.id 在 MemDBUtils 中若 id 列不存在会被置为 0（兼容旧表）；在此处保留该行为但应意识到多个无 id 的记录会有相同 id=0，可能影响按 id 操作（删除/编辑）
          const id: number = r.id ?? 0;
          const title: string = r.title ?? '';
          // targetDate 仅在为 number 时被视为有效，其他类型（字符串）会被忽略并视为 undefined
          const date: Date | number | undefined = (
            typeof r.targetDate === 'number' && !isNaN(r.targetDate)) ? r.targetDate : undefined;
          const type: MemoryType = r.finished ? 'anniversary' : 'countdown';
          return { id, title, date, type } as MemoryItem;
        });
        this.events = mapped;
      } else {
        // 数据库返回为空；显示空列表
        this.events = [];
      }
      // 默认可见月份与当前日期同步（留作未来使用）
      if (!this.selectedDate) {
        this.visibleMonth = new Date();
      }
    } catch (err) {
      // 读取/解析数据库过程中发生错误时，记录日志并清空 events 以保证 UI 的一致性
      console.log(`加载记忆列表失败: ${err}`);
      this.events = [];
    }
  }

  // 提供图片来源：优先使用持久化路径，否则使用打包资源
  private imageSource(): string | Resource {
    if (this.headerImagePath && this.headerImagePath.length > 0) {
      return this.headerImagePath;
    }
    return $r('app.media.hixy_logo_new');
  }

  // 为 dateUtils 标准化事件：确保存在日期并避免使用展开语法
  private normalizeEvents(events: MemoryItem[]): MemoryItem[] {
    const list: MemoryItem[] = [];
    if (!events) {
      return list;
    }
    for (const e of events) {
      // 统一补全日期，避免 dateUtils 计算异常
      const normalized: MemoryItem = {
        id: e.id,
        title: e.title,
        date: e.date !== undefined && e.date !== null ? e.date : new Date(),
        type: e.type,
        note: e.note
      };
      list.push(normalized);
    }
    return list;
  }

  // 按剩余天数升序返回事件
  private getEventsSortedByDaysUntil(): MemoryItem[] {
    const safeEvents: MemoryItem[] = this.normalizeEvents(this.events);
    return dateUtils.getEventsSortedByDaysUntil(safeEvents, undefined, (e: MemoryItem) => e.type === 'anniversary');
  }

  // 已排序事件的公共别名（保持调用处兼容）
  private sorted(): MemoryItem[] {
    return this.getEventsSortedByDaysUntil();
  }

    // 打开添加记忆页面
    private openAddMemory(): void {
      // 新增时将 selectedId 置为 0（新建），跳转到编辑页；编辑页通常会在保存后设置 AppStorage needsReload 为 true
      AppStorage.Set<number>('selectedId', 0);
      router.push({ uri: 'pages/EditMemory' });
    }
  }
