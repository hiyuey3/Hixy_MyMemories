/**
 * HomeHeader 组件：首页顶部图片和标题区域
 * 职责：展示头部图片和"倒数日 | 纪念日"标题
 */
import { MemoryItem } from '../types/MemoryTypes';
import * as dateUtils from '../utils/dateUtils';

interface HomeHeaderProps {
  headerImagePath: string;
  events: MemoryItem[];
}

@Component
export struct HomeHeader {
  @Prop headerImagePath: string;
  @Prop events: MemoryItem[];

  private getUpcoming(): number {
    return dateUtils.countUpcoming(this.events, undefined, (e) => e.type === 'anniversary');
  }

  private getMemories(): number {
    return dateUtils.countMemories(this.events, undefined, (e) => e.type === 'anniversary');
  }

  private imageSource(): string | Resource {
    if (this.headerImagePath && this.headerImagePath.length > 0) {
      return this.headerImagePath;
    }
    return $r('app.media.hixy_logo_new');
  }

  build() {
    Column({ space: 12 }) {
      // Header Image
      Column() {
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

      // Statistics Row
      Column({ space: 8 }) {
        Text('倒数日 | 纪念日')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F1F1F');

        Row({ space: 12 }) {
          // Upcoming Events Card
          Column() {
            Text(`${this.getUpcoming()}`)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Red);
            Text('即将到来')
              .fontSize(13)
              .fontColor(Color.Black);
          }
          .backgroundColor(Color.Transparent)
          .borderWidth(2)
          .borderColor(Color.Gray)
          .padding(12)
          .width('48%')
          .height(80)
          .borderRadius(12);

          // Past Memories Card
          Column() {
            Text(`${this.getMemories()}`)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF7A45');
            Text('纪念回顾')
              .fontSize(13)
              .fontColor('#666');
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
      .padding({
        left: 18,
        right: 18,
        top: 20,
        bottom: 12
      });
    }
  }
}

