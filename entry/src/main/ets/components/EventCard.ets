// 事件卡片组件：展示单个事件的标题、日期、类型与天数信息
// 主要职责：
// - 接收一个 MemoryItem，计算并展示日期/倒数/纪念信息
// - 提供纯展示逻辑，所有计算委托到 dateUtils
// 输入/输出：
// - @Prop item: MemoryItem（id、title、date、type、note）
// 调用逻辑：
// - 内部封装了日期格式化、天数文本、天数颜色等辅助函数
// - build() 使用这些 helper 渲染 UI，保持组件无副作用
// 错误与边界：
// - 对 dateUtils 的返回做 NaN 检查，空或非法日期显示空串

import { MemoryItem, DateLike } from '../types/MemoryTypes';
import * as dateUtils from '../utils/dateUtils';
import router from '@system.router';

@Component
export struct EventCard {
  @Prop item: MemoryItem;

  private formatDate(d: DateLike): string {
    // 格式化日期为 yyyy-MM-dd，如输入无效返回空
    return dateUtils.formatDate(d);
  }

  private daysTextFor(item: MemoryItem): string {
    // 文本化天数：纪念日显示距下次(已过)，倒数日显示剩余或已过
    return dateUtils.daysTextFor(item.date, undefined, item.type === 'anniversary');
  }

  private daysColorFor(item: MemoryItem): string {
    // 根据天数差返回颜色（未来为蓝，已过为橙）
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
    // 渲染：左侧色条 + 主要信息 + 右侧天数/状态
    // 详细布局保留原有实现
    Row({ space: 10 }) {
      // Left vertical accent bar (shorter, vertically centered)
      Blank()
        .width(4)
        .height(40)
        .alignSelf(ItemAlign.Center)
        .backgroundColor(this.item.type === 'countdown' ? '#5A7CC2' : '#FF7F50')
        .borderRadius(2);

      // Main card content
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
            // .backgroundColor(this.item.type === 'countdown' ? '#5A7CC2' : '#FF7A45')
            .backgroundColor(this.item.type === 'countdown' ? '#5A7CC2' : '#FF7F50')
            .borderRadius(12);

          if (this.item.type === 'anniversary') {
            Text(this.anniversaryUntilText(this.item))
              .fontSize(14)
              .margin({ top: 6, bottom: 2 })
              .fontColor('#4166F5');
            Text(this.anniversarySinceText(this.item))
              .fontSize(12)
              .fontColor('#FF7F50');
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
        .width(120)
        .alignItems(HorizontalAlign.End)
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .padding(14)
      .backgroundColor($r('app.color.start_window_background'))
      .borderRadius(14)
      .width('95%')
      .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 4 });
    }
    .width('99%')
    .onClick(() => {
      // Navigate to detail page for this item
      AppStorage.Set<number>('selectedId', this.item.id);
      router.push({ uri: 'pages/EventDetail', params: { id: this.item.id } });
    });
  }
}
