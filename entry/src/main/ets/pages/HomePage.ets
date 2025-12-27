// 首页内容组件：头图、统计、列表和操作按钮 / Home content component: header, stats, list, actions
import { MemoryItem } from '../types/MemoryTypes';
import * as dateUtils from '../utils/dateUtils';
import { EventCard } from '../components/EventCard';

@Preview
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

  build() {
    Column({ space: 12 }) {
      // 头图 / header image
      Column() {
        Image(this.imageSource)
          .id('headerImage')
          .width(340)
          .height(120)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
          .align(Alignment.Center);
      }
      .height('120')
      .width('100%')
      .padding({ top: 16 });

      Column({ space: 8 }) {
        Text('倒数日 | 纪念日').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#1F1F1F');
        Row({ space: 12 }) {

          Column() {
            Text(`${this.getUpcoming()}`).fontSize(24).fontWeight(FontWeight.Bold)
              .fontColor('#1677FF');
            Text('即将到来').fontSize(12).fontColor('#666');
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
            Text(`${this.getMemories()}`).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FF7A45');
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

      List({ space: 10 }) {
        ForEach(this.getEventsSortedByDaysUntil(), (item: MemoryItem) => {
          ListItem() {
            EventCard({ item: item });
          }
        })
      }
      .edgeEffect(EdgeEffect.None)
      .width('100%')
      .height('100%')
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
    .height('100%')
    .backgroundColor('#F7F8FA');
  }
}
