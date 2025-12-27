// import { Settings } from './Settings';
import { MemoryDBUtil, Memory } from '../utils/MemDBUtils';
import * as dateUtils from '../utils/dateUtils';
import router from '@system.router';
import { About } from './About';
import { MemoryItem, MemoryType, DateLike } from '../types/MemoryTypes';
import promptAction from '@ohos.promptAction';


@Entry
@Component
struct Index {
  // events loaded from DB via MemoryDBUtil
  @State events: MemoryItem[] = [];
  @State currentIndex: number = 0;
  // @State addFeedback: string = '';
  // Persisted header image uri
  @State headerImagePath: string = '';
  private tabsController: TabsController = new TabsController();
  // no burst refresh timers; rely on lifecycle + explicit reload on tab click
  private toast(msg: string): void {
    try { promptAction.showToast({ message: msg }); } catch (_) {}
  }

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
          Column({ space: 12 }) {
            Column() {
              // Single Image with dynamic source (shown as circle via borderRadius)
              Image(this.imageSource())
                .id('headerImage')
                .width(340)
                .height(120)
                .objectFit(ImageFit.Cover)
                .borderRadius(15)
                .align(Alignment.Center);
            }
            .height('120')
            .width('100%')
            .padding({ top: 18 });

            Column({ space: 8 }) {
              Text('倒数日 | 纪念日').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1F1F1F');
              Row({ space: 12 }) {

                Column() {
                  Text(`${this.getUpcoming()}`).fontSize(28).fontWeight(FontWeight.Bold)
                    // .fontColor('#1677FF');
                    .fontColor(Color.Red)
                  Text('即将到来').fontSize(13).fontColor(Color.Black);
                }
                .backgroundColor(Color.Transparent)
                .borderWidth(2)
                .borderColor(Color.Gray)
                .padding(12)
                .width('48%')
                .height(80)
                // .backgroundColor('#F2F6FF')
                .borderRadius(12);

                Column() {
                  Text(`${this.getMemories()}`).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FF7A45');
                  Text('纪念回顾').fontSize(13).fontColor('#666');
                }
                .width('48%')
                .height(80)
                .padding(12)
                .backgroundColor(Color.Transparent)
                .borderWidth(2)
                .borderColor(Color.Gray)
                // .backgroundColor('#FFF4EC')
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
              Button('➕ 新增事件')
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
              // if (this.addFeedback.length > 0) {
              //   Text(this.addFeedback).fontSize(12).fontColor('#fff').margin({ left: 8 });
              // }
              // 管理按钮（打开管理页面）
              Button('✍️管理')
                .type(ButtonType.Normal)
                .backgroundColor('#ffffff')
                .borderColor(Color.Gray)
                .borderWidth(1)
                .borderRadius(3)
                .fontColor('#1677FF')
                .width('20%')
                .height(39)
                .margin({ left: 8 })
                .onClick(() => {
                  this.toast('打开管理页面...');
                  try { router.push({ uri: 'pages/ManageMemories' }); } catch (_) { this.toast('无法打开管理页面'); }
                });

             }
             .justifyContent(FlexAlign.Center)
             .padding({ bottom: 10 });

          }
          .width('100%')
          .height('100%')
          .backgroundColor('#F7F8FA');
          // .backgroundColor(Color.Pink);
        }
        .tabBar(this.TabBuilder('首页', 0,$r('app.media.foreground')));

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
                    // write AppStorage as compatibility fallback, and prefer passing id via router params
                    try { AppStorage.Set<number>('selectedId', item.id); } catch (e) {}
                    try {
                      router.push({ uri: 'pages/EventDetail', params: { id: item.id } });
                    } catch (e) {
                      // fallback to plain push if params not supported
                      try { router.push({ uri: 'pages/EventDetail' }); } catch (err) { console.error(err); }
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
      // include 'target_date' so we can use the user-selected date from DB
      const cols = ['id', 'task_name', 'finished', 'target_date'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      if (rows && rows.length > 0) {
        this.events = rows.map((r: Memory) => {
          const id: number = r.id ?? 0;
          const title: string = r.title ?? '';
          // Use targetDate if available, otherwise undefined (let MemoryItem handle null dates)
          const date = (typeof r.targetDate === 'number') ? r.targetDate : undefined;
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
    return $r('app.media.hixy_logo_new');
  }

  // Return events sorted by days until (ascending)
  private getEventsSortedByDaysUntil(): MemoryItem[] {
    return dateUtils.getEventsSortedByDaysUntil(this.events, undefined, (e) => e.type === 'anniversary');
  }

  // Public alias for sorted events (keeps call sites stable)
  private sorted(): MemoryItem[] {
    return this.getEventsSortedByDaysUntil();
  }

  // Count of upcoming (daysDiff >= 0)
  private getUpcoming(): number {
    return dateUtils.countUpcoming(this.events, undefined, (e) => e.type === 'anniversary');
  }

  // Count of past memories (daysDiff < 0) - all types combined
  private getMemories(): number {
    return dateUtils.countMemories(this.events, undefined, (e) => e.type === 'anniversary');
  }

  // Helper: formatted days text for an item
  private daysTextFor(item: MemoryItem): string {
    return dateUtils.daysTextFor(item.date, undefined, item.type === 'anniversary');
  }

  // Helper: color for the days text (upcoming vs past)
  private daysColorFor(item: MemoryItem): string {
    return dateUtils.daysColorFor(item.date, undefined, item.type === 'anniversary');
  }

  // Helper: date formatting wrapper
  private formatDate(d: DateLike): string {
    return dateUtils.formatDate(d);
  }

  @Builder
  private EventCard(item: MemoryItem): void {
    // Blank()
    // Use helper methods for calculations so Builder only contains UI syntax
    Row({ space: 1}) {
      Column({ space: 1 }) {

        Row() {
          Column() {
            Text(item.title)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Start)
              .fontColor('#111')
              .maxLines(1)
            // .position({left:0,top:0});
            // .overflow(TextOverflow.Ellipsis);
            // .position({left:0,bottom:3});
            Text(this.formatDate(item.date))
              .fontSize(13)
              .fontColor('#666')
              .textAlign(TextAlign.Start)
            // .alignSelf()
            // .position({ left: 0, bottom });

          }
          .alignItems(HorizontalAlign.Start)
        }
      }

      Column(){
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
        Text(this.daysTextFor(item))
          .fontSize(14)
          .margin({top:6 ,bottom: 6 })
          .fontColor(this.daysColorFor(item));
      }
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

  @Builder
  private TabBuilder(title: string, targetIndex: number, normalImg?: Resource, selectedImg?: Resource) {
    Column() {
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
      try {
        this.tabsController.changeIndex(this.currentIndex);
      } catch (e) {
        console.error(e);
      }
      // If user clicks back to Home tab, reload data immediately
      if (targetIndex === 0) {
        this.loadEvents();
        try { setTimeout(() => this.loadEvents(), 300); } catch (e) {}
      }
    });
  }

  // Open AddMemory page with logging and error handling
  private openAddMemory(): void {
    try {
      // Clear AppStorage selectedId to ensure we don't load any previous record
      try { AppStorage.Set<number>('selectedId', 0); } catch (e) {}
      // this.addFeedback = '点击：正在尝试跳转...';
      console.log('Add button clicked: attempting to navigate to AddMemory');
      try { promptAction.showToast({ message: '跳转到新增事件...' }); } catch (e) {}
      try {
        router.push({ uri: 'pages/EditMemory' });
        console.log('router.push called for pages/AddMemory');
        // this.addFeedback = '跳转请求已发送';
        try { promptAction.showToast({ message: '已请求跳转' }); } catch (e) {}
      } catch (pushErr) {
        console.error('router.push threw for pages/AddMemory:', pushErr);
        // this.addFeedback = '跳转失败';
        try { promptAction.showToast({ message: '跳转失败' }); } catch (e) {}
      }
    } catch (err) {
      console.error('router.push failed for pages/AddMemory:', err);
      // this.addFeedback = '跳转失败';
      try { promptAction.showToast({ message: '跳转失败' }); } catch (e) { console.error(e); }
    }
   }
 }
