// 事件详情页：展示详情并提供编辑与删除 / Event detail page with edit & delete
import router from '@system.router';
import { MemoryDBUtil, Memory } from '../utils/MemDBUtils';
import * as dateUtils from '../utils/dateUtils';
import { MemoryItem } from '../types/MemoryTypes';

@Entry
@Component
export struct EventDetail {
  @State item: MemoryItem | undefined = undefined;

  aboutToAppear() {
    const selectedId: number | undefined = AppStorage.Get<number>('selectedId');
    const id: number | undefined = selectedId;
    if (typeof id === 'number') {
      this.loadItem(id);
    }
  }

  private async loadItem(id: number): Promise<void> {
    try {
      const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', ['id', 'task_name', 'finished', 'target_date']);
      const row = rows.find(r => r.id === id);
      if (row) {
        const item: MemoryItem = {
          id: row.id ?? 0,
          title: row.title ?? '',
          date: (typeof row.targetDate === 'number' && !isNaN(row.targetDate)) ? row.targetDate : undefined,
          type: row.finished ? 'anniversary' : 'countdown'
        };
        this.item = item;
      }
    } catch (e) {
      console.log('加载详情失败: ' + e);
    }
  }

  private formatDate(): string {
    if (!this.item) return '';
    return dateUtils.formatDate(this.item.date);
  }

  private async deleteItem(): Promise<void> {
    if (!this.item) return;
    try {
      await MemoryDBUtil.deleteMemoryById('memories', this.item.id);
      router.back();
    } catch (e) {
      console.log('删除失败: ' + e);
    }
  }

  private goEdit(): void {
    if (!this.item) return;
    AppStorage.Set<number>('selectedId', this.item.id);
    router.push({ uri: 'pages/EditMemory', params: { id: this.item.id } });
  }

  build() {
    Column({ space: 12 }) {
      if (!this.item) {
        Text('加载中…').fontSize(16).fontColor('#666');
      } else {
        Column({ space: 8 }) {
          Text(this.item.title).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#111');
          Row({ space: 10 }) {
            Text(this.item.type === 'countdown' ? '倒数' : '纪念')
              .fontSize(12)
              .fontColor('#fff')
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor(this.item.type === 'countdown' ? '#1677FF' : '#FF7A45')
              .borderRadius(12);
            Text(this.formatDate()).fontSize(14).fontColor('#666');
          }
        }
        .padding({ left: 18, right: 18, top: 20 });

        Row({ space: 12 }) {
          Button('编辑')
            .type(ButtonType.Capsule)
            .fontColor('#fff')
            .backgroundColor('#1677FF')
            .width('40%')
            .height(42)
            .onClick(() => this.goEdit());

          Button('删除')
            .type(ButtonType.Capsule)
            .fontColor('#fff')
            .backgroundColor('#FF4D4F')
            .width('40%')
            .height(42)
            .onClick(() => {
              // 简易确认：再次点击才删除
              // 可替换为自定义弹窗组件以获得更佳体验
              this.deleteItem();
            });
        }
        .justifyContent(FlexAlign.Center)
        .padding({ bottom: 20 });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA');
  }
}
