import promptAction from '@ohos.promptAction';
import { Memories } from './pages/Memories';
import { Settings } from './pages/Settings';

type MemoryType = 'countdown' | 'anniversary';
interface MemoryItem {
  id: number;
  title: string;
  date: Date;
  type: MemoryType;
  note?: string;
}

@Entry
@Component
struct Index {
  @State events: MemoryItem[] = [
    { id: 1, title: '生日', date: new Date('2025-06-18'), type: 'anniversary' },
    { id: 2, title: '假期出发', date: new Date('2025-10-01'), type: 'countdown' },
    { id: 3, title: '相识纪念', date: new Date('2024-12-12'), type: 'anniversary' }
  ];
  @State showForm: boolean = false;
  @State newTitle: string = '';
  @State newDate: Date = new Date();
  @State newType: MemoryType = 'countdown';
  @State currentIndex: number = 0;
  // 基础 TabBar 高度，64 为设计高度；bottomInset 用于适配安全区（动态可替换）
  private tabBarBaseHeight: number = 64;
  @State bottomInset: number = 0; // 若要接入设备安全区，请在 onInit() 中读取并设置此值

  private tabsController: TabsController = new TabsController();

  private formatDate(d: Date): string {
    const y = d.getFullYear();
    const m = `${d.getMonth() + 1}`.padStart(2, '0');
    const day = `${d.getDate()}`.padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  private daysDiff(target: Date): number {
    const today = new Date();
    const start = new Date(today.getFullYear(), today.getMonth(), today.getDate()).getTime();
    const dest = new Date(target.getFullYear(), target.getMonth(), target.getDate()).getTime();
    const diff = Math.round((dest - start) / (24 * 3600 * 1000));
    return diff;
  }

  private getEventsSortedByDaysUntil(): MemoryItem[] {
    return [...this.events].sort((a, b) => this.daysDiff(a.date) - this.daysDiff(b.date));
  }

  // Compatibility wrapper: some code calls this.sorted(), keep that API
  private sorted(): MemoryItem[] {
    return this.getEventsSortedByDaysUntil();
  }

  // Added small helpers so @Builder methods contain only UI syntax
  private getUpcoming(): number {
    return this.events.filter(i => this.daysDiff(i.date) >= 0).length;
  }

  private getMemories(): number {
    return this.events.filter(i => this.daysDiff(i.date) < 0).length;
  }

  private addItem(): void {
    if (!this.newTitle.trim()) {
      try {
        promptAction.showToast({ message: '请输入标题' });
      } catch (e) {
        console.error(e);
      }
      return;
    }
    const next: MemoryItem = {
      id: Date.now(),
      title: this.newTitle.trim(),
      date: new Date(this.newDate),
      type: this.newType
    };
    this.events = [...this.events, next];
    this.newTitle = '';
    this.newDate = new Date();
    this.newType = 'countdown';
    this.showForm = false;
    try {
      promptAction.showToast({ message: '已添加' });
    } catch (e) {
      console.error(e);
    }
  }

  @Builder
  private SummaryCard(): void {
    Column({ space: 8 }) {
      Text('倒数日 & 纪念日')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F1F1F');
      Row({ space: 12 }) {
        Column() {
          Text(`${this.getUpcoming()}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1677FF');
          Text('即将到来')
            .fontSize(13)
            .fontColor('#666');
        }
        .padding(12)
        .backgroundColor('#F2F6FF')
        .borderRadius(12);

        Column() {
          Text(`${this.getMemories()}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF7A45');
          Text('纪念回顾')
            .fontSize(13)
            .fontColor('#666');
        }
        .padding(12)
        .backgroundColor('#FFF4EC')
        .borderRadius(12);
      }
    }
    .padding({ left: 18, right: 18, top: 20, bottom: 12 })
  }

  @Builder
  private EventCard(item: MemoryItem): void {
    Row({ space: 8 }) {
      Column({ space: 6 }) {
        Text(item.title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111');
        Text(this.formatDate(item.date))
          .fontSize(13)
          .fontColor('#666');
        Text(this.daysDiff(item.date) >= 0 ? `还有 ${this.daysDiff(item.date)} 天` : `已过 ${Math.abs(this.daysDiff(item.date))} 天`)
          .fontSize(14)
          .fontColor(this.daysDiff(item.date) >= 0 ? '#1677FF' : '#FF7A45');
      }
      Text(item.type === 'countdown' ? '倒数' : '纪念')
        .fontSize(12)
        .fontColor('#fff')
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .backgroundColor(item.type === 'countdown' ? '#1677FF' : '#FF7A45')
        .borderRadius(12);
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .padding(14)
    .backgroundColor($r('app.color.start_window_background'))
    .borderRadius(14)
    .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  private AddForm(): void {
    Column({ space: 14 }) {
      Text('新增倒数日/纪念日')
        .fontSize(18)
        .fontWeight(FontWeight.Medium);
      TextInput({ placeholder: '标题，如：旅行、生日…', text: this.newTitle })
        .onChange((v: string) => this.newTitle = v);
      Row({ space: 10 }) {
        Text('类型').fontSize(14).fontColor('#666');
        Toggle({ type: ToggleType.Button, isOn: this.newType === 'countdown' })
          .onChange((v: boolean) => this.newType = v ? 'countdown' : 'anniversary');
        Text(this.newType === 'countdown' ? '倒数日' : '纪念日').fontSize(14).fontColor('#666');
      }
      Column({ space: 6 }) {
        Text('日期').fontSize(14).fontColor('#666');
        DatePicker({
          start: new Date('2000-01-01'),
          end: new Date('2100-12-31'),
          selected: this.newDate
        })
        .onDateChange((date: Date) => {
          this.newDate = date;
        });
      }
      Row({ space: 12 }) {
        Button('取消')
          .backgroundColor('#F2F2F2')
          .fontColor('#333')
          .onClick(() => this.showForm = false)
          .width('48%');
        Button('保存')
          .type(ButtonType.Capsule)
          .backgroundColor('#1677FF')
          .fontColor('#fff')
          .onClick(() => this.addItem())
          .width('48%');
      }
    }
    .padding(18)
    .backgroundColor($r('app.color.start_window_background'))
    .borderRadius({ topLeft: 20, topRight: 20, bottomLeft: 12, bottomRight: 12 })
  }

  @Builder
  private TabBuilder(title: string, targetIndex: number, normalImg?: Resource, selectedImg?: Resource){
    Column() {
      // 选中态上方高亮条
      Column() {
        Box().height(3).width('36px').borderRadius(2).backgroundColor(this.currentIndex == targetIndex ? '#1677FF' : 'transparent').align(Alignment.Center);
      }
      .height(6)
      .width('100%')
      .align(Alignment.Center);

      Image(normalImg ? (this.currentIndex == targetIndex ? selectedImg ?? normalImg : normalImg) : $r('app.media.startIcon'))
        .width(24)
        .height(24)
        .align(Alignment.Center);

      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex == targetIndex ? '#1677FF' : '#333')
        .align(Alignment.Center)
        .margin({ top: 6 });
    }
    .width('100%')
    .height(this.tabBarBaseHeight)
    .justifyContent(FlexAlign.Center)
    .padding({ bottom: this.bottomInset })
    .onClick(() => {
      this.currentIndex = targetIndex;
      try {
        this.tabsController.changeIndex(this.currentIndex);
      } catch (e) {
        console.error(e);
      }
    })
  }

  build() {
    Stack() {
      // Tabs 容器：底部 TabBar（barPosition: End）
      Tabs({ barPosition: BarPosition.End, controller: this.tabsController, index: this.currentIndex }) {
        // 首页 TabContent：保留原有主页布局
        TabContent() {
          Column({ space: 12 }) {
            // Top center group photo
            Column() {
              Image($r('app.media.background'))
                .width(310)
                .height(150)
                .objectFit(ImageFit.Cover)
                .borderRadius(20)
                .align(Alignment.Center);
            }
            .height('160px')
            .width('100%')
            .padding({ top: 18 });

            this.SummaryCard();
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
            .padding({ left: 18, right: 18, bottom: 80 });

            Row() {
              Button('+ 新增事件')
                .type(ButtonType.Capsule)
                .backgroundColor('#1677FF')
                .fontColor('#fff')
                .width('70%')
                .height(44)
                .onClick(() => this.showForm = true);
            }
            .justifyContent(FlexAlign.Center)
            .padding({ bottom: 16 });
          }
          .height('100%')
          .width('100%')
          .backgroundColor('#F7F8FA');
        }
        .tabBar(this.TabBuilder('首页', 0));

        // 记忆 TabContent（拆分到独立组件）
        TabContent() {
          Memories()
        }
        .tabBar(this.TabBuilder('记忆', 1, $r('app.media.foreground')));

        // 设置 TabContent（拆分到独立组件）
        TabContent() {
          Settings()
        }
        .tabBar(this.TabBuilder('设置', 2, $r('app.media.foreground')));
      }
      .width('100%')
      .height('100%')
      .scrollable(false)
      .animationDuration(0);

      // 弹窗：遮罩高度保留底部 TabBar（64px）
      if (this.showForm) {
        Column() {
          const totalBarHeight = this.tabBarBaseHeight + this.bottomInset;
          Blank().height(`calc(100% - ${totalBarHeight}px)`).width('100%').backgroundColor('#80000000')
            .onClick(() => this.showForm = false);
          this.AddForm();
        }
        .align(Alignment.Bottom)
      }
    }

    .height('100%')
    .width('100%')
  }
}