// 记忆列表页面（独立） / Memories tab page with calendar filter
import router from '@system.router';
import { MemoryItem, DateLike } from '../types/MemoryTypes';
import { EventCard } from '../components/EventCard';

@Entry
@Component
export struct MemoriesPage {
  @Prop events: MemoryItem[] = [];
  @State selectedDate: Date | null = null;
  @State visibleMonth: Date = this.getMonthStart(new Date());
  @State jumpInput: string = '';

  aboutToAppear(): void {
    // 同步可见月份到今日（未选择时）
    if (!this.selectedDate) {
      this.visibleMonth = this.getMonthStart(new Date());
    }
  }

  private sameDay(a: Date, b: Date): boolean {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  }

  private toDate(v: DateLike): Date | null {
    if (v instanceof Date) { return v; }
    if (typeof v === 'number') { return new Date(v); }
    if (typeof v === 'string') { return new Date(v); }
    return null;
  }

  private getMonthStart(d: Date): Date {
    return new Date(d.getFullYear(), d.getMonth(), 1);
  }

  private getDaysInMonth(d: Date): number {
    return new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
  }

  private getWeekdayOfFirst(d: Date): number {
    const wd = new Date(d.getFullYear(), d.getMonth(), 1).getDay(); // 0=Sun..6=Sat
    return wd === 0 ? 7 : wd; // 1..7
  }

  private weekLabels(): string[] {
    return ['一', '二', '三', '四', '五', '六', '日'];
  }

  private getMonthMatrix(d: Date): (number | null)[][] {
    const lead: number = this.getWeekdayOfFirst(d) - 1;
    const days: number = this.getDaysInMonth(d);
    const cells: (number | null)[] = [];
    for (let idx = 0; idx < 42; idx++) {
      const dayNum: number = idx - lead + 1;
      cells.push(dayNum <= 0 || dayNum > days ? null : dayNum);
    }
    const rows: (number | null)[][] = [];
    for (let i = 0; i < 6; i++) {
      rows.push(cells.slice(i * 7, i * 7 + 7));
    }
    return rows;
  }

  private getEventDaysInVisibleMonth(): Set<number> {
    const set = new Set<number>();
    const baseMonth: Date = this.visibleMonth;
    this.events.forEach((e: MemoryItem) => {
      const d = this.toDate(e.date);
      if (d && d.getFullYear() === baseMonth.getFullYear() && d.getMonth() === baseMonth.getMonth()) {
        set.add(d.getDate());
      }
    });
    return set;
  }

  private shiftVisibleMonth(offset: number): void {
    const y = this.visibleMonth.getFullYear();
    const m = this.visibleMonth.getMonth();
    this.visibleMonth = new Date(y, m + offset, 1);
  }

  private filteredEvents(): MemoryItem[] {
    if (!this.selectedDate) {
      return this.events || [];
    }
    const target: Date = this.selectedDate;
    return (this.events || []).filter((e: MemoryItem) => {
      const d = this.toDate(e.date);
      return d ? this.sameDay(d, target) : false;
    });
  }

  @Builder
  private renderWeekHeader(labels: string[]): void {
    Row({ space: 4 }) {
      ForEach(labels, (w: string) => {
        Text(w).fontSize(11).fontColor('#888').width('12.5%').align(Alignment.Center);
      });
    }
  }

  @Builder
  private renderCalendarGrid(matrix: (number | null)[][], markedDays: Set<number>): void {
    ForEach(matrix, (row: (number | null)[]) => {
      Row({ space: 4 }) {
        ForEach(row, (day: number | null) => {
          if (day === null) {
            Blank().width('12.5%').height(10);
          } else {
            Button(`${day}`)
              .type(ButtonType.Capsule)
              .backgroundColor((this.selectedDate && this.sameDay(new Date(this.visibleMonth.getFullYear(), this.visibleMonth.getMonth(), day), this.selectedDate)) ? '#1677FF' : (markedDays.has(day) ? '#E6F0FF' : '#F9FAFB'))
              .fontColor((this.selectedDate && this.sameDay(new Date(this.visibleMonth.getFullYear(), this.visibleMonth.getMonth(), day), this.selectedDate)) ? '#fff' : '#333')
              .width('12.5%')
              .height(32)
              .onClick(() => {
                const picked = new Date(this.visibleMonth.getFullYear(), this.visibleMonth.getMonth(), day);
                if (this.selectedDate && this.sameDay(picked, this.selectedDate)) {
                  this.selectedDate = null;
                } else {
                  this.selectedDate = picked;
                  this.visibleMonth = this.getMonthStart(picked);
                }
              });
          }
        });
      }
    });
  }

  build() {
    Column({ space: 12 }) {
      Text('记忆').fontSize(20).fontWeight(FontWeight.Bold).padding({ top: 6, left: 6, right: 6 });

      // 月历选择（过滤列表）
      Column({ space: 6 }) {
        Column({ space: 6 }) {
          Text(`${this.visibleMonth.getFullYear()}年${this.visibleMonth.getMonth() + 1}月`).fontSize(20).fontWeight(FontWeight.Medium).align(Alignment.Center);
          this.renderWeekHeader(this.weekLabels());
          this.renderCalendarGrid(this.getMonthMatrix(this.visibleMonth), this.getEventDaysInVisibleMonth());
          Row({ space: 8 }) {
            Button('<').type(ButtonType.Circle).onClick(() => this.shiftVisibleMonth(-1)).layoutWeight(1).height(30);
            Button('今日').type(ButtonType.Capsule).onClick(() => {
               const today = new Date();
               this.visibleMonth = this.getMonthStart(today);
               this.selectedDate = today;
               this.jumpInput = `${today.getFullYear()}-${today.getMonth() + 1}-${today.getDate()}`;
             }).layoutWeight(1).height(29);
            Button('清除').type(ButtonType.Capsule).onClick(() => {
               this.selectedDate = null;
             }).layoutWeight(1).height(29);
            Button('>').type(ButtonType.Circle).onClick(() => this.shiftVisibleMonth(1)).layoutWeight(1).height(30);
           }.padding({left: 10, right: 10});
        }
        // 跳转指定日期
        Row({ space: 8 }) {
          TextInput({ placeholder: 'YYYY-MM-DD', text: this.jumpInput }).onChange((v: string) => this.jumpInput = v).layoutWeight(1).height(33);
          Button('跳转').type(ButtonType.Capsule).onClick(() => {
            try {
              const parsed = new Date(this.jumpInput);
              if (isNaN(parsed.getTime())) { return; }
              this.visibleMonth = this.getMonthStart(parsed);
              this.selectedDate = parsed;
            } catch (_) {}
          }).width(88).height(33);
        }
        // .height(30)
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(5)
        .borderColor('#F0F1F3')
        .borderWidth(1)
        .shadow({ radius: 6, color: '#1A000000', offsetX: 0, offsetY: 2 });
      }

      List({ space: 10 }) {
        ForEach(this.filteredEvents(), (item: MemoryItem) => {
          ListItem() {
            EventCard({ item: item });
          }
          .onClick(() => {
            AppStorage.Set<number>('selectedId', item.id);
            router.push({ uri: 'pages/EventDetail', params: { id: item.id } });
          });
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
}
