// 公共卡片组件：展示标题、日期、类型和天数 / Shared event card component
/**
 * EventCard 组件：事件卡片
 * 职责：展示单个事件的标题、日期、类型和剩余天数
 */
import { MemoryItem, DateLike } from '../types/MemoryTypes';
import * as dateUtils from '../utils/dateUtils';

interface EventCardProps {
  item: MemoryItem;
}

@Component
export struct EventCard {
  @Prop item: MemoryItem;

  private formatDate(d: DateLike): string {
    return dateUtils.formatDate(d);
  }

  private daysTextFor(item: MemoryItem): string {
    return dateUtils.daysTextFor(item.date, undefined, item.type === 'anniversary');
  }

  private daysColorFor(item: MemoryItem): string {
    return dateUtils.daysColorFor(item.date, undefined, item.type === 'anniversary');
  }

  // Countdown helper: status text
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
    // 标题 + 日期 / title and date
    Row({ space: 1 }) {
      Column({ space: 1 }) {
        Row() {
          Column() {
            Text(this.item.title)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Start)
              .fontColor('#111')
              .maxLines(1);

            Text(this.formatDate(this.item.date))
              .fontSize(13)
              .fontColor('#666')
              .textAlign(TextAlign.Start);
          }
          .alignItems(HorizontalAlign.Start);
        }
      }

      Column() {
        // 类型标签与天数字 / type badge and days text
        Text(this.item.type === 'countdown' ? '倒数' : '纪念')
          .fontSize(12)
          .fontColor('#fff')
          .padding({
            left: 10,
            right: 10,
            top: 4,
            bottom: 4
          })
          .backgroundColor(this.item.type === 'countdown' ? '#1677FF' : '#FF7A45')
          .borderRadius(12);

        if (this.item.type === 'anniversary') {
          Text(this.anniversaryUntilText(this.item))
            .fontSize(14)
            .margin({ top: 6, bottom: 2 })
            .fontColor('#1677FF');
          Text(this.anniversarySinceText(this.item))
            .fontSize(12)
            .fontColor('#FF7A45');
        } else {
          Text(this.daysTextFor(this.item))
            .fontSize(14)
            .margin({ top: 6, bottom: 2 })
            .fontColor(this.daysColorFor(this.item));
          Text(this.countdownStatusText(this.item))
            .fontSize(12)
            .fontColor('#666');
        }
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
}
