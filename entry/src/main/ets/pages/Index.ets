import { Settings } from './Settings';
import { MemoryDBUtil, Memory } from '../utils/MemDBUtils';
import router from '@system.router';
import { About } from './About';
import { MemoryItem, MemoryType } from '../types/MemoryTypes';
import promptAction from '@ohos.promptAction';


@Entry
@Component
struct Index {
  // events loaded from DB via MemoryDBUtil
  @State events: MemoryItem[] = [];
  @State currentIndex: number = 0;
  @State addFeedback: string = '';
  // Persisted header image uri
  @State headerImagePath: string = '';
  private tabsController: TabsController = new TabsController();

  onInit(): void {
    // Initialize DB and load events
    this.loadHeaderImage();
    this.loadEvents();
    // If Add page set needsReload flag, refresh again shortly after init
    try { if (AppStorage.Get<boolean>('needsReload')) { AppStorage.Set<boolean>('needsReload', false); setTimeout(() => this.loadEvents(), 300); } } catch (e) {}
  }

  onShow(): void {
    // Reload events whenever page is shown
    this.loadEvents();
    // needsReload hint
    try { if (AppStorage.Get<boolean>('needsReload')) { AppStorage.Set<boolean>('needsReload', false); setTimeout(() => this.loadEvents(), 300); } } catch (e) {}
  }

  onDestroy(): void {}

  // Image picking feature removed: header image may still be set via resources or persistent path.

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, controller: this.tabsController, index: this.currentIndex }) {
        // Home tab
        TabContent() {
          Column({ space: 12 }) {
            Column() {
              // Single Image with dynamic source (shown as circle via borderRadius)
              Image(this.imageSource())
                .id('headerImage')
                .width(320)
                .height(170)
                .objectFit(ImageFit.Cover)
                .borderRadius(15)
                .align(Alignment.Center);
            }
            .height('160px')
            .width('100%')
            .padding({ top: 18 });

            Column({ space: 8 }) {
              Text('倒数日 & 纪念日').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1F1F1F');
              Row({ space: 12 }) {
                Column() {
                  Text(`${this.getUpcoming()}`).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#1677FF');
                  Text('即将到来').fontSize(13).fontColor('#666');
                }
                .padding(12)
                .backgroundColor('#F2F6FF')
                .borderRadius(12);

                Column() {
                  Text(`${this.getMemories()}`).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FF7A45');
                  Text('纪念回顾').fontSize(13).fontColor('#666');
                }
                .padding(12)
                .backgroundColor('#FFF4EC')
                .borderRadius(12);
              }
            }
            .padding({
              left: 18,
              right: 18,
              top: 20,
              bottom: 12
            });

            List({ space: 10 }) {
              ForEach(this.sorted(), (item: MemoryItem) => {
                ListItem() {
                  this.EventCard(item);
                }
              })
            }
            .edgeEffect(EdgeEffect.None)
            .width('100%')
            .height('100%')
            .layoutWeight(1)
            .padding({ left: 18, right: 18, bottom: 10 });

            Row() {
              Button('+ 新增事件')
                .type(ButtonType.Capsule)
                // 添加阴影
                .shadow({
                  radius: 6,
                  color: '#1A000000',
                  offsetX: -4,
                  offsetY: 10
                })
                .borderColor(Color.White)
                .borderStyle(BorderStyle.Solid)
                .borderWidth(2)
                .backgroundColor(Color.Pink)
                .fontColor('#fff')
                .width('70%')
                .height(39)
                .onClick(() => this.openAddMemory());
              // visible feedback for debugging
              if (this.addFeedback.length > 0) {
                Text(this.addFeedback).fontSize(12).fontColor('#fff').margin({ left: 8 });
              }
              // 管理按钮（打开管理页面）
              Button('管理')
                .type(ButtonType.Capsule)
                .backgroundColor('#ffffff')
                .fontColor('#1677FF')
                .width('20%')
                .height(39)
                .margin({ left: 8 })
                .onClick(() => {
                  try {
                    promptAction.showToast({ message: '打开管理页面...' });
                  } catch (e) {}
                  try { router.push({ uri: 'pages/ManageMemories' }); } catch (err) { try { promptAction.showToast({ message: '无法打开管理页面' }); } catch (e) {} }
                });
             }
             .justifyContent(FlexAlign.Center)
             .padding({ bottom: 10 });

          }
          .width('100%')
          .height('100%')
          // .backgroundColor('#F7F8FA');
          .backgroundColor(Color.Pink);
        }
        .tabBar(this.TabBuilder('首页', 0));

        // Memories tab
        TabContent() {
          Column({ space: 12 }) {
            List({ space: 10 }) {
              ForEach(this.sorted(), (item: MemoryItem) => {
                ListItem() {
                  Column() {
                    this.EventCard(item);
                  }
                  .onClick(() => {
                    // persist selected id so detail page can read it
                    AppStorage.Set<number>('selectedId', item.id);
                    try {
                      router.push({ uri: 'pages/EventDetail' });
                    } catch (e) {
                      console.error(e);
                    }
                  });
                }
              })
            }
            .edgeEffect(EdgeEffect.None)
            .width('100%')
            .height('100%')
            .layoutWeight(1)
            .padding({ left: 18, right: 18, bottom: 18 });
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#F7F8FA');
        }
        .tabBar(this.TabBuilder('记忆', 1, $r('app.media.foreground')));

        // Settings tab
        TabContent() {
          Settings()
        }
        .tabBar(this.TabBuilder('设置', 2, $r('app.media.foreground')));

        // About tab
        TabContent() {
          About()
        }
        .tabBar(this.TabBuilder('关于', 3, $r('app.media.foreground')));

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
      const cols = ['id', 'task_name', 'finished'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      if (rows && rows.length > 0) {
        this.events = rows.map(r => {
          const id: number = r.id ?? 0;
          const title: string = r.title ?? '';
          const date = new Date();
          const type: MemoryType = r.finished ? 'anniversary' : 'countdown';
          return { id, title, date, type } as MemoryItem;
        });
      } else {
        // DB returned empty; show empty list (no MemoryStore fallback per requirement)
        this.events = [];
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
    return $r('app.media.background');
  }

  // Format a Date to yyyy-mm-dd for display
  private formatDate(d: Date): string {
    const y = d.getFullYear();
    const m = `${d.getMonth() + 1}`.padStart(2, '0');
    const day = `${d.getDate()}`.padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  // Days difference between today (midnight) and target date (midnight)
  private daysDiff(target: Date): number {
    const today = new Date();
    const start = new Date(today.getFullYear(), today.getMonth(), today.getDate()).getTime();
    const dest = new Date(target.getFullYear(), target.getMonth(), target.getDate()).getTime();
    return Math.round((dest - start) / (24 * 3600 * 1000));
  }

  // Return events sorted by days until (ascending)
  private getEventsSortedByDaysUntil(): MemoryItem[] {
    return [...this.events].sort((a, b) => this.daysDiff(a.date) - this.daysDiff(b.date));
  }

  // Public alias for sorted events (keeps call sites stable)
  private sorted(): MemoryItem[] {
    return this.getEventsSortedByDaysUntil();
  }

  // Count of upcoming (daysDiff >= 0)
  private getUpcoming(): number {
    return this.events.filter(i => this.daysDiff(i.date) >= 0).length;
  }

  // Count of past memories (daysDiff < 0)
  private getMemories(): number {
    return this.events.filter(i => this.daysDiff(i.date) < 0).length;
  }

  @Builder
  private EventCard(item: MemoryItem): void {
    Blank()
    // Use helper methods for calculations so Builder only contains UI syntax
    Row({ space: 8 }) {
      Column({ space: 6 }) {
        Text(item.title).fontSize(18).fontWeight(FontWeight.Medium).fontColor('#111');
        Text(this.formatDate(item.date)).fontSize(13).fontColor('#666');
        Text(this.daysTextFor(item))
          .fontSize(14)
          .fontColor(this.daysColorFor(item));
      }

      Text(item.type === 'countdown' ? '倒数' : '纪念')
        .fontSize(12)
        .fontColor('#fff')
        .padding({
          left: 10,
          right: 10,
          top: 4,
          bottom: 4
        })
        .backgroundColor(item.type === 'countdown' ? '#1677FF' : '#FF7A45')
        .borderRadius(12);
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .padding(14)
    .backgroundColor($r('app.color.start_window_background'))
    .borderRadius(14)
    .width('100%')
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 4
    });
  }

  // Helper: formatted days text for an item
  private daysTextFor(item: MemoryItem): string {
    const diff = this.daysDiff(item.date);
    return diff >= 0 ? `还有 ${diff} 天` : `已过 ${Math.abs(diff)} 天`;
  }

  // Helper: color for the days text (upcoming vs past)
  private daysColorFor(item: MemoryItem): string {
    return this.daysDiff(item.date) >= 0 ? '#1677FF' : '#FF7A45';
  }

  @Builder
  private TabBuilder(title: string, targetIndex: number, normalImg?: Resource, selectedImg?: Resource) {
    Column() {
      Image(normalImg ? (this.currentIndex === targetIndex ? selectedImg ?? normalImg : normalImg) :
        $r('app.media.startIcon'))
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
      try {
        this.tabsController.changeIndex(this.currentIndex);
      } catch (e) {
        console.error(e);
      }
    });
  }

  // Open AddMemory page with logging and error handling
  private openAddMemory(): void {
    try {
      this.addFeedback = '点击：正在尝试跳转...';
      console.log('Add button clicked: attempting to navigate to AddMemory');
      try { promptAction.showToast({ message: '跳转到新增事件...' }); } catch (e) {}
      try {
        router.push({ uri: 'pages/AddMemory' });
        console.log('router.push called for pages/AddMemory');
        this.addFeedback = '跳转请求已发送';
        try { promptAction.showToast({ message: '已请求跳转' }); } catch (e) {}
      } catch (pushErr) {
        console.error('router.push threw for pages/AddMemory:', pushErr);
        this.addFeedback = '跳转失败';
        try { promptAction.showToast({ message: '跳转失败' }); } catch (e) {}
      }
    } catch (err) {
      console.error('router.push failed for pages/AddMemory:', err);
      this.addFeedback = '跳转失败';
      try { promptAction.showToast({ message: '跳转失败' }); } catch (e) { console.error(e); }
    }
   }
 }
