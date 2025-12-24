import router from '@system.router';
import { MemoryItem, MemoryType } from '../types/MemoryTypes';
import promptAction from '@ohos.promptAction';
import { MemoryDBUtil, Memory } from '../utils/MemDBUtils';
import { relationalStore } from '@kit.ArkData';

@Entry
@Component
export struct ManageMemories {
  @State events: MemoryItem[] = [];
  // no MemoryStore subscription; refresh from DB on lifecycle hooks

  onInit(): void {
    // Load from DB at start
    this.loadEvents();
    try {
      const off = MemoryDBUtil.subscribe(() => { this.loadEvents(); });
      AppStorage.Set<() => void>('__mgr_unsub__', off);
    } catch (e) {}
  }

  onDestroy(): void {
    try {
      const off = AppStorage.Get<() => void>('__mgr_unsub__');
      if (off) off();
      AppStorage.Delete('__mgr_unsub__');
    } catch (e) {}
  }

  onShow(): void {
    this.loadEvents();
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Text('管理记忆').fontSize(20).fontWeight(FontWeight.Bold);
        Button('新增')
          .type(ButtonType.Capsule)
          .onClick(() => this.onAdd())
          .backgroundColor('#1677FF')
          .fontColor('#fff');
        // Debug: 测试写入 - 会尝试写入一条示例数据并查询 DB 行数
        Button('测试写入')
          .type(ButtonType.Capsule)
          .margin({ left: 8 })
          .onClick(() => {
            this.testWrite();
          })
          .backgroundColor('#00AA66')
          .fontColor('#fff');
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

  private async loadEvents(): Promise<void> {
    try {
      const cols: string[] = ['id', 'task_name', 'finished'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      this.events = (rows || []).map((r: Memory) => {
        const id: number = r.id ?? 0;
        const title: string = r.title ?? '';
        const date: Date = new Date();
        const type: MemoryType = r.finished ? 'anniversary' : 'countdown';
        return { id, title, date, type } as MemoryItem;
      });
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
      try { await MemoryDBUtil.deleteMemoryById('memories', id); } catch (e) { console.error('DB delete failed', e); }
      await this.loadEvents();
      try { promptAction.showToast({ message: '已删除' }); } catch (e) {}
    } catch (err) {
      console.error('删除失败', err);
      try { promptAction.showToast({ message: '删除失败' }); } catch (e) {}
    }
  }

  private formatDate(d: Date): string {
    try {
      const y = d.getFullYear();
      const m = `${d.getMonth() + 1}`.padStart(2, '0');
      const day = `${d.getDate()}`.padStart(2, '0');
      return `${y}-${m}-${day}`;
    } catch (e) { return '' }
  }

  // Debug helper: write a test row and query DB using MemDBUtils directly
  private async testWrite(): Promise<void> {
    const title = `Test ${Date.now()}`;
    try {
      const vb: relationalStore.ValuesBucket = { task_name: title, finished: 0 } as relationalStore.ValuesBucket;
      const rowId: number = await MemoryDBUtil.insertMemory('memories', vb);
      if (rowId && rowId > 0) {
        try { promptAction.showToast({ message: `写入成功 id=${rowId}` }); } catch (e) {}
      }
    } catch (e) {
      console.error('testWrite: DB insert failed', e);
      try { promptAction.showToast({ message: '写入失败 (DB insert)' }); } catch (e2) {}
      return;
    }

    try {
      // small delay to let DB operation complete
      await new Promise<void>((resolve) => setTimeout(resolve, 500));
      const cols: string[] = ['id', 'task_name', 'finished'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      const cnt = rows ? rows.length : 0;
      try { promptAction.showToast({ message: `测试写入完成，DB 行数: ${cnt}` }); } catch (e) {}
      console.log('testWrite: query rows:', rows);
      // refresh UI from DB rows
      this.events = (rows || []).map((r: Memory) => {
        const id: number = r.id ?? 0;
        const t: string = r.title ?? '';
        const date: Date = new Date();
        const type: MemoryType = r.finished ? 'anniversary' : 'countdown';
        return { id, title: t, date, type } as MemoryItem;
      });
    } catch (e) {
      console.error('testWrite: query failed', e);
      try { promptAction.showToast({ message: '查询失败' }); } catch (e2) {}
    }
  }
}
