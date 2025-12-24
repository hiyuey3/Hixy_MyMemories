import MemoryStore from '../store/MemoryStore';
import { MemoryItem } from '../types/MemoryTypes';
import router from '@system.router';

@Component
export struct EventDetail {
  @State itemId: number | undefined = undefined;
  @State item: MemoryItem | undefined = undefined;

  onInit(): void {
    const id = MemoryStore.getSelected();
    this.itemId = id;
    if (id) this.item = MemoryStore.getEventById(id);
  }

  private goEdit(): void {
    if (this.itemId) {
      try { router.push({ uri: 'pages/EditMemory', params: { id: this.itemId } }); } catch (e) { console.warn(e); }
    }
  }

  private doDelete(): void {
    if (!this.itemId) return;
    MemoryStore.deleteEvent(this.itemId);
    try { router.back(); } catch (e) { console.warn(e); }
  }

  build() {
    Column({ space: 12 }) {
      if (this.item) {
        Text(this.item.title).fontSize(22).fontWeight(FontWeight.Bold).align(Alignment.Center).margin({ top: 24 });
        Text(this.item.date.toDateString()).fontSize(14).fontColor('#666').align(Alignment.Center);
        Text(this.item.type === 'countdown' ? '倒数' : '纪念').fontSize(14).fontColor('#333').align(Alignment.Center);

        Row({ space: 12 }) {
          Button('编辑').onClick(() => this.goEdit()).width('48%');
          Button('删除').backgroundColor('#FF4D4F').fontColor('#fff').onClick(() => this.doDelete()).width('48%');
        }
        .padding({ top: 20 })
      } else {
        Text('未找到该事件').fontSize(16).align(Alignment.Center).margin({ top: 40 });
      }
    }
    .width('100%')
    .height('100%')
    .padding(18)
  }
}
