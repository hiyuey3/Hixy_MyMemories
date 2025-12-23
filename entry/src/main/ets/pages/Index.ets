import promptAction from '@ohos.promptAction';

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
      promptAction.showToast({ message: '请输入标题' });
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
    promptAction.showToast({ message: '已添加' });
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
    .backgroundColor('#FFFFFF')
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
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 20, topRight: 20, bottomLeft: 12, bottomRight: 12 })
  }

  build() {
    Stack() {
      Column({ space: 12 }) {
        // Top center group photo
        Column() {
          Image($r('app.media.background'))
            .width('120px')
            .height('120px')
            .objectFit(ImageFit.Cover)
            .borderRadius(60)
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

      // Bottom navigation bar
      Column() {
        Blank().height('100%').width('100%').backgroundColor('#0000').onClick(() => {});
        Row({ space: 10 }) {
          Column() {
            Image($r('app.media.foreground')).width('24px').height('24px').align(Alignment.Center);
            Text('首页').fontSize(12).fontColor('#333').align(Alignment.Center);
          }
          .onClick(() => { /* navigate Home */ })
          Column() {
            Image($r('app.media.foreground')).width('24px').height('24px').align(Alignment.Center);
            Text('记忆').fontSize(12).fontColor('#333').align(Alignment.Center);
          }
          .onClick(() => { /* navigate Memories */ })
          Column() {
            Image($r('app.media.foreground')).width('24px').height('24px').align(Alignment.Center);
            Text('设置').fontSize(12).fontColor('#333').align(Alignment.Center);
          }
          .onClick(() => { /* navigate Settings */ })
        }
        .height(64)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 0, bottomRight: 0 })
        .padding({ left: 30, right: 30 })
        .justifyContent(FlexAlign.SpaceBetween);
      }

      if (this.showForm) {
        Column() {
          Blank().height('100%').width('100%').backgroundColor('#80000000')
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