import MemoryStore from '../store/MemoryStore';
import router from '@system.router';
import { MemoryItem } from '../types/MemoryTypes';
import promptAction from '@ohos.promptAction';

@Entry
@Component
export struct ManageMemories {
  @State events: MemoryItem[] = [];
  private unsub: (() => void) | null = null;

  onInit(): void {
    // MemoryStore may be initialized elsewhere (EntryAbility); just load current events
    this.loadEvents();

    // subscribe to store updates
    try {
      this.unsub = MemoryStore.subscribe(() => {
        this.loadEvents();
      });
    } catch (e) {}
  }

  onDestroy(): void {
    if (this.unsub) {
      try { this.unsub(); } catch (e) {}
      this.unsub = null;
    }
  }

  private loadEvents(): void {
    try {
      this.events = MemoryStore.getEvents();
    } catch (err) {
      console.log(`加载记忆失败: ${err}`);
      this.events = [];
    }
  }

  private async onAdd(): Promise<void> {
    try {
      router.push({ uri: 'pages/AddMemory' });
    } catch (e) {
      try { promptAction.showToast({ message: '无法跳转到新增页面' }); } catch (e) {}
      console.error('跳转 AddMemory 失败', e);
    }
  }

  private async onEdit(item: MemoryItem): Promise<void> {
    try {
      AppStorage.Set<number>('selectedId', item.id);
      router.push({ uri: 'pages/EditMemory' });
    } catch (e) {
      try { promptAction.showToast({ message: '无法跳转到编辑页面' }); } catch (e) {}
      console.error('跳转 EditMemory 失败', e);
    }
  }

  private async onDelete(id: number): Promise<void> {
    try {
      // call delete without awaiting (MemoryStore type may be non-Promise in ambient typings)
      try { MemoryStore.deleteEvent(id); } catch (e) { console.error('调用 deleteEvent 失败', e); }
      // refresh local view immediately
      this.loadEvents();
      try { promptAction.showToast({ message: '已删除' }); } catch (e) {}
    } catch (err) {
      console.error('删除失败', err);
      try { promptAction.showToast({ message: '删除失败' }); } catch (e) {}
    }
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Text('管理记忆').fontSize(20).fontWeight(FontWeight.Bold);
        Button('新增').type(ButtonType.Capsule).onClick(() => this.onAdd()).backgroundColor('#1677FF').fontColor('#fff');
      }
      .padding({ left: 16, right: 16, top: 16 });

      List({ space: 8 }) {
        ForEach(this.events, (item: MemoryItem) => {
          ListItem() {
            Row({ space: 12 }) {
              Column() {
                Text(item.title).fontSize(16).fontWeight(FontWeight.Medium);
                Text(this.formatDate(item.date)).fontSize(12).fontColor('#666');
              }
              .layoutWeight(1)

              Row() {
                Button('编辑').onClick(() => this.onEdit(item)).backgroundColor('#F2F2F2');
                Button('删除').onClick(() => this.onDelete(item.id)).backgroundColor('#FF7A45').fontColor('#fff');
              }
              .justifyContent(FlexAlign.Center)
            }
            .padding(12)
            .backgroundColor(Color.White)
            .borderRadius(10)
          }
        })
      }
      .padding({ left: 16, right: 16, bottom: 16 })
      .width('100%')
      .height('100%')
      .edgeEffect(EdgeEffect.None)
      .layoutWeight(1)

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA');
  }

  private formatDate(d: Date): string {
    try {
      const y = d.getFullYear();
      const m = `${d.getMonth() + 1}`.padStart(2, '0');
      const day = `${d.getDate()}`.padStart(2, '0');
      return `${y}-${m}-${day}`;
    } catch (e) { return '' }
  }
}
