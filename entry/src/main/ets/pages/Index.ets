// 首页容器：负责 Tab 切换与数据加载 / Root page: tabs + data loading
import { MemoryDBUtil, Memory } from '../utils/MemDBUtils';
import * as dateUtils from '../utils/dateUtils';
import router from '@system.router';
import { About } from './About';
import { MemoryItem, MemoryType } from '../types/MemoryTypes';
import { HomePage } from './HomePage';
import { MemoriesPage } from './MemoriesPage';


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
  private tabsController: TabsController = new TabsController();
  // no burst refresh timers; rely on lifecycle + explicit reload on tab click

  onInit(): void {
    // Initialize DB and load events
    this.loadHeaderImage();
    this.loadEvents();
  }

  onShow(): void {
    // Reload events whenever page is shown
    this.loadEvents();
    // start a short burst refresh to catch recent writes
  }

  aboutToAppear(): void {
    // Force re-query DB when page appears
    this.loadEvents();
    // Small delayed refresh to ensure DB commit is visible on slower devices
    try { setTimeout(() => this.loadEvents(), 300); } catch (e) {}
    // also start a short burst refresh
  }

  onDestroy(): void {}

  // Image picking feature removed: header image may still be set via resources or persistent path.

  build() {
    Column() {

      Tabs({ barPosition: BarPosition.End, controller: this.tabsController, index: this.currentIndex }) {
        // Home tab
        TabContent() {
          HomePage({
            events: this.events,
            imageSource: this.imageSource(),
            onAdd: () => this.openAddMemory(),
            onManage: () => {
              router.push({ uri: 'pages/ManageMemories' });
            }
          });
        }
        .tabBar(this.TabBuilder('首页', 0,$r('app.media.foreground')));

        // Memories tab
        TabContent() {
          MemoriesPage({ events: this.sorted() })
        }
        .tabBar(this.TabBuilder('记忆', 1, $r('app.media.foreground')));

        // Settings tab
        // TabContent() {
          // Settings()
        // }
        // .tabBar(this.TabBuilder('设置', 2, $r('app.media.foreground')));

        // About tab
        TabContent() {
          About()
        }
        .tabBar(this.TabBuilder('关于', 2, $r('app.media.foreground')));

      }
      .width('100%')
      .height('100%')
      .scrollable(false)
      .backgroundColor(Color.Pink)
      .animationDuration(0);

    }
    .width('100%')
    .height('100%');
  }

  // Load header path from persistent storage (if present)
  private loadHeaderImage(): void {
    const stored = AppStorage.Get<string>('headerImagePath');
    this.headerImagePath = stored ?? '';
  }

  // Load events from DB and map to MemoryItem[]
  private async loadEvents(): Promise<void> {
    try {
      // 查询 DB 并组装渲染数据 / fetch rows then hydrate for UI
      const cols = ['id', 'task_name', 'finished', 'target_date'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      if (rows && rows.length > 0) {
        this.events = rows.map((r: Memory) => {
          const id: number = r.id ?? 0;
          const title: string = r.title ?? '';
          // Use targetDate if available; ensure we pass a primitive ms value to avoid DateLike mismatch
          const date = (typeof r.targetDate === 'number' && !isNaN(r.targetDate)) ? r.targetDate : undefined;
          const type: MemoryType = r.finished ? 'anniversary' : 'countdown';
          return { id, title, date, type } as MemoryItem;
        });
      } else {
        // DB returned empty; show empty list (no MemoryStore fallback per requirement)
        this.events = [];
      }
      // 默认可见月份与当前日期同步（留作未来使用）
      if (!this.selectedDate) {
        this.visibleMonth = new Date();
      }
    } catch (err) {
      console.log(`加载记忆列表失败: ${err}`);
      this.events = [];
    }
  }

  // Provide image source: persisted path wins, otherwise bundled resource
  private imageSource(): string | Resource {
    if (this.headerImagePath && this.headerImagePath.length > 0) {
      return this.headerImagePath;
    }
    return $r('app.media.hixy_logo_new');
  }

  // Normalize events for dateUtils: ensure date is present and avoid spread (ArkTS no-spread rule)
  private normalizeEvents(events: MemoryItem[]): MemoryItem[] {
    const list: MemoryItem[] = [];
    if (!events) {
      return list;
    }
    for (const e of events) {
      // 统一补全日期，避免 dateUtils 计算异常 / ensure date present for dateUtils
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

  // Return events sorted by days until (ascending)
  private getEventsSortedByDaysUntil(): MemoryItem[] {
    const safeEvents: MemoryItem[] = this.normalizeEvents(this.events);
    return dateUtils.getEventsSortedByDaysUntil(safeEvents, undefined, (e: MemoryItem) => e.type === 'anniversary');
  }

  // Public alias for sorted events (keeps call sites stable)
  private sorted(): MemoryItem[] {
    return this.getEventsSortedByDaysUntil();
  }

  @Builder
  private TabBuilder(title: string, targetIndex: number, normalImg?: Resource, selectedImg?: Resource) {
    Column() {
      // Tab 图标与标题 / Tab icon & label
      Image(normalImg ? (this.currentIndex === targetIndex ? selectedImg ?? normalImg : normalImg) :
        $r('app.media.hixy_logo_new'))
        .width(24)
        .height(24)
        .align(Alignment.Center);
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === targetIndex ? '#ff4116ff' : '#333')
        .align(Alignment.Center)
        .margin({ top: 6 });
    }
    .width('100%')
    .height(64)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
      this.tabsController.changeIndex(this.currentIndex);
      if (targetIndex === 0) {
        // 返回首页时即时刷新 / force refresh when switching to Home
        this.loadEvents();
        setTimeout(() => this.loadEvents(), 300);
      }
    });
  }

   // Open AddMemory page with minimal error handling
   private openAddMemory(): void {
     AppStorage.Set<number>('selectedId', 0);
     router.push({ uri: 'pages/EditMemory' });
   }
 }
