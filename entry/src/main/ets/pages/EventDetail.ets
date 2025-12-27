// 事件详情页：展示详情并提供编辑与删除 / Event detail page with edit & delete
import router from '@system.router';
import { MemoryDBUtil, Memory } from '../utils/MemDBUtils';
import * as dateUtils from '../utils/dateUtils';
import { MemoryItem } from '../types/MemoryTypes';

interface RouteParams { id?: number }

@Entry
@Component
export struct EventDetail {
  @State item: MemoryItem | undefined = undefined;
  private unsub?: () => void;

  aboutToAppear() {
    const params: RouteParams = (router.getParams() as RouteParams);
    const paramId: number | undefined = typeof params?.id === 'number' ? params.id : undefined;
    const selectedId: number | undefined = AppStorage.Get<number>('selectedId');
    const id: number | undefined = paramId ?? selectedId;
    if (typeof id === 'number') {
      this.loadItem(id);
      // subscribe to DB changes to refresh when data updates
      try { this.unsub = MemoryDBUtil.subscribe(() => this.loadItem(id)); } catch (_) {}
    }
  }

  onDestroy() {
    if (this.unsub) {
      try { this.unsub(); } catch (_) {}
      this.unsub = undefined;
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
      } else {
        // not found: show placeholder to avoid infinite loading
        this.item = { id, title: '未找到记录', date: undefined, type: 'countdown' } as MemoryItem;
      }
    } catch (e) {
      console.log('加载详情失败: ' + e);
      // show placeholder on error
      this.item = { id, title: '加载失败', date: undefined, type: 'countdown' } as MemoryItem;
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
    router.push({ uri: 'pages/EditMemory', params: { editId: this.item.id } });
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

        if (this.item.title === '未找到记录' || this.item.title === '加载失败') {
          Text('提示：未找到该事件或加载失败').fontSize(12).fontColor('#999').padding({ left: 18 });
        }

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
