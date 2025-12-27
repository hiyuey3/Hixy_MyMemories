// 首页内容组件：头图、统计、列表和操作按钮 / Home content component: header, stats, list, actions
import { MemoryItem, DateLike } from '../types/MemoryTypes';
import * as dateUtils from '../utils/dateUtils';

@Component
export struct HomePage {
  @Prop events: MemoryItem[] = [];
  @Prop imageSource: string | Resource;
  onAdd: () => void = () => {}; //
  onManage: () => void = () => {};

  // Ensure events all carry a date for dateUtils
  private normalizeEvents(events: MemoryItem[]): MemoryItem[] {
    const list: MemoryItem[] = [];
    if (!events) {
      return list;
    }
    for (const e of events) {
      // dateUtils 需要日期；为空则用今天 / ensure date present for dateUtils
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

  private getEventsSortedByDaysUntil(): MemoryItem[] {
    const safeEvents: MemoryItem[] = this.normalizeEvents(this.events);
    return dateUtils.getEventsSortedByDaysUntil(safeEvents, undefined, (e: MemoryItem) => e.type === 'anniversary');
  }

  private getUpcoming(): number {
    const safeEvents: MemoryItem[] = this.normalizeEvents(this.events);
    return dateUtils.countUpcoming(safeEvents, undefined, (e: MemoryItem) => e.type === 'anniversary');
  }

  private getMemories(): number {
    const safeEvents: MemoryItem[] = this.normalizeEvents(this.events);
    return dateUtils.countMemories(safeEvents, undefined, (e: MemoryItem) => e.type === 'anniversary');
  }

  private daysTextFor(item: MemoryItem): string {
    return dateUtils.daysTextFor(item.date, undefined, item.type === 'anniversary');
  }

  private daysColorFor(item: MemoryItem): string {
    return dateUtils.daysColorFor(item.date, undefined, item.type === 'anniversary');
  }

  private formatDate(d: DateLike): string {
    return dateUtils.formatDate(d);
  }

  // Countdown helper: status line text
  private countdownStatusText(item: MemoryItem): string {
    const diff = dateUtils.daysDiff(item.date, undefined, false);
    if (isNaN(diff)) return '';
    return diff >= 0 ? '倒计时中' : '已过期';
  }

  // Anniversary helpers
  private anniversarySinceText(item: MemoryItem): string {
    const stats = dateUtils.anniversaryStats(item.date, undefined);
    if (isNaN(stats.daysSince)) return '';
    return `已过 ${stats.daysSince} 天`;
  }

  private anniversaryUntilText(item: MemoryItem): string {
    const stats = dateUtils.anniversaryStats(item.date, undefined);
    if (isNaN(stats.daysUntil)) return '';
    return `距下次 ${stats.daysUntil} 天`;
  }

  build() {
    Column({ space: 12 }) {
      // 头图 / header image
      Column() {
        Image(this.imageSource)
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
              .fontColor(Color.Red);
            Text('即将到来').fontSize(13).fontColor(Color.Black);
          }
          .backgroundColor(Color.Transparent)
          .borderWidth(2)
          .borderColor(Color.Gray)
          .padding(12)
          .width('48%')
          .height(80)
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
          .borderRadius(12);
        }
      }
      .padding({ left: 18, right: 18, top: 20, bottom: 12 });

      List({ space: 10 }) {
        ForEach(this.getEventsSortedByDaysUntil(), (item: MemoryItem) => {
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
          .shadow({ radius: 6, color: '#1A000000', offsetX: -4, offsetY: 10 })
          .borderColor(Color.White)
          .borderStyle(BorderStyle.Solid)
          .borderWidth(2)
          .backgroundColor(Color.Pink)
          .fontColor('#fff')
          .width('70%')
          .height(39)
          .onClick(() => this.onAdd());

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
          .onClick(() => this.onManage());

       }
       .justifyContent(FlexAlign.Center)
       .padding({ bottom: 10 });

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA');
  }

  @Builder
  private EventCard(item: MemoryItem): void {
    // 单条卡片 / single event card
    Row({ space: 1}) {
      Column({ space: 1 }) {
        Row() {
          Column() {
            Text(item.title)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Start)
              .fontColor('#111')
              .maxLines(1);

            Text(this.formatDate(item.date))
              .fontSize(13)
              .fontColor('#666')
              .textAlign(TextAlign.Start);
          }
          .alignItems(HorizontalAlign.Start);
        }
      }

      Column(){
        Text(item.type === 'countdown' ? '倒数' : '纪念')
          .fontSize(12)
          .fontColor('#fff')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor(item.type === 'countdown' ? '#1677FF' : '#FF7A45')
          .borderRadius(12);
        if (item.type === 'anniversary') {
          Text(this.anniversaryUntilText(item))
            .fontSize(14)
            .margin({ top: 6, bottom: 2 })
            .fontColor('#1677FF');
          Text(this.anniversarySinceText(item))
            .fontSize(12)
            .fontColor('#FF7A45');
        } else {
          Text(this.daysTextFor(item))
            .fontSize(14)
            .margin({ top: 6, bottom: 2 })
            .fontColor(this.daysColorFor(item));
          Text(this.countdownStatusText(item))
            .fontSize(12)
            .fontColor('#666');
        }
      }
      .width(120)
      .alignItems(HorizontalAlign.End);
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .padding(14)
    .backgroundColor($r('app.color.start_window_background'))
    .borderRadius(14)
    .width('100%')
    .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 4 });
  }
}
