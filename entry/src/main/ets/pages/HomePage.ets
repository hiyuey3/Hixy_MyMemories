// HomePage 组件：主页内容区域（头图、统计、事件列表、操作）
// 主要职责：
// - 接收外部传入的事件数组并提供统计与排序显示
// - 提供“新增”操作回调
// - 将事件规范化（保证 date 可用）以便于 dateUtils 使用
// 输入/输出：
// - props: events (MemoryItem[]), imageSource (string|Resource)
// - callbacks: onAdd()
// 错误与边界：
// - 对传入 events 做空和类型容错，返回空数组以保证 UI 不崩溃

import { MemoryItem } from '../types/MemoryTypes';
import * as dateUtils from '../utils/dateUtils';
import { EventCard } from '../components/EventCard';

@Preview
@Component
export struct HomePage {
  @Prop events: MemoryItem[] = [];
  @Prop imageSource: string | Resource;
  onAdd: () => void = () => {}; // 回调：点击新增
  onManage: () => void = () => {}; // 回调：进入管理页

  // 工具：确保事件拥有有效日期，避免 dateUtils 抛错
  private normalizeEvents(events: MemoryItem[]): MemoryItem[] {
    const list: MemoryItem[] = [];
    if (!events) {
      return list;
    }
    for (const e of events) {
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

  // 获取按天数排序的事件（由 dateUtils 提供）
  private getEventsSortedByDaysUntil(): MemoryItem[] {
    const safeEvents: MemoryItem[] = this.normalizeEvents(this.events);
    return dateUtils.getEventsSortedByDaysUntil(safeEvents, undefined, (e: MemoryItem) => e.type === 'anniversary');
  }

  // 统计即将到来的事件数量
  private getUpcoming(): number {
    const safeEvents: MemoryItem[] = this.normalizeEvents(this.events);
    return dateUtils.countUpcoming(safeEvents, undefined, (e: MemoryItem) => e.type === 'anniversary');
  }

  // 统计已过的纪念事件数量
  private getMemories(): number {
    const safeEvents: MemoryItem[] = this.normalizeEvents(this.events);
    return dateUtils.countMemories(safeEvents, undefined, (e: MemoryItem) => e.type === 'anniversary');
  }

  build() {
    // 构建 UI，结构清晰，错误容忍
    Column({ space: 12 }) {
      // 头图
      Column() {
        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.header_banner'))
            .id('headerImage')
            .width(360)
            .height(140)
            .objectFit(ImageFit.Cover)
            .borderRadius(16)
            .align(Alignment.Center);

          Column({ space: 4 }) {
            Text('记录重要时刻')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#F5F7FB')
              .textAlign(TextAlign.Center);
            Text('倒数日 · 纪念日 · 管理器')
              .fontSize(12)
              .fontColor('#E8F4FF')
              .textAlign(TextAlign.Center);
          }
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor('#33000000')
          .borderRadius(12)
          .align(Alignment.BottomEnd)
          .margin({ right: 16, bottom: 12 });
        }
        .width('100%')
        .height(140);
      }
      .padding({ top: 16 })
      .width('100%')
      .height('140');

      // 统计卡片与事件列表
      Column({ space: 8 }) {
        Text('倒数日 | 纪念日').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#1F1F1F');
        Row({ space: 12 }) {
          Column() {
            Text(`${this.getUpcoming()}`).fontSize(28).fontWeight(FontWeight.Bold)
              .fontColor('#5A7CC2');
            Text('即将到来').fontSize(13).fontColor(Color.Black);
          }
          .backgroundColor('#FFFFFF')
          .borderWidth(1)
          .borderColor('#E5E7EB')
          .padding(10)
          .width('48%')
          .height(72)
          .borderRadius(10)
          .shadow({ radius: 4, color: '#12000000', offsetX: 0, offsetY: 2 });

          Column() {
            Text(`${this.getMemories()}`).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FF7F50');
            Text('纪念回顾').fontSize(12).fontColor('#666');
          }
          .width('48%')
          .height(72)
          .padding(10)
          .backgroundColor('#FFFFFF')
          .borderWidth(1)
          .borderColor('#E5E7EB')
          .borderRadius(10)
          .shadow({ radius: 4, color: '#12000000', offsetX: 0, offsetY: 2 });
        }
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 12 });

      // 列表区
      List({ space: 10 }) {
        ForEach(this.getEventsSortedByDaysUntil(), (item: MemoryItem) => {
          ListItem() {
            EventCard({ item: item });
          }
        })
      }
      .edgeEffect(EdgeEffect.None)
      .layoutWeight(1)
      .padding({ left: 16, right: 16, bottom: 10 });

      Row() {
        Button('➕ 新增事件')
          .type(ButtonType.Capsule)
          .shadow({ radius: 4, color: '#12000000', offsetX: 0, offsetY: 2 })
          .backgroundColor('#1677FF')
          .fontColor('#FFFFFF')
          .width('85%')
          .height(40)
           .onClick(() => this.onAdd());

        // 管理入口已迁移到「关于」页面底部，仅保留新增按钮在首页

       }
       .justifyContent(FlexAlign.Center)
       .padding({ bottom: 12 });

    }
    .width('100%')
    .height('100%');
  }
}
