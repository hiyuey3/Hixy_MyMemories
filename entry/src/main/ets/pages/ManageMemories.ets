import router from '@system.router';
import { MemoryItem, MemoryType, DateLike } from '../types/MemoryTypes';
import { MemoryDBUtil, Memory, makeValuesBucket } from '../utils/MemDBUtils';
import { relationalStore } from '@kit.ArkData';
import { formatDate as formatDateUtil } from '../utils/dateUtils';
import vibrator from '@ohos.vibrator';

@Entry
@Component
export struct ManageMemories {
  @State events: MemoryItem[] = [];
  @State deleteTargetId: number | undefined = undefined;

  onInit(): void {
    // Load from DB at start
    this.loadEvents();
  }

  // no MemoryStore subscription; refresh from DB on lifecycle hooks

  onDestroy(): void {
    // no-op
  }

  onShow(): void {
    this.loadEvents();
  }

  // Called when this page is about to appear (safer than relying on back navigation)
  aboutToAppear(): void {
    // immediate refresh
    this.loadEvents();
    // delayed refresh to catch DB commits that may be slightly delayed
    try {
      setTimeout(() => this.loadEvents(), 300);
    } catch (e) {
    }
  }

  build() {
    Column({ space: 12 }) {
      // Inline per-item confirmation: when deleteTargetId === item.id render confirm UI

      Row({ space: 12 }) {
        Column() {
          Row() {
            Text('管理记忆')
              .fontSize(20)
              .backgroundColor(Color.Transparent)
              .textAlign(TextAlign.Center)
              // .width('45%')
              .fontWeight(FontWeight.Bold)

          }

          Blank().margin({ bottom: 8 });
          Row() {
            Button('➕')
              .type(ButtonType.Capsule)
              .onClick(() => this.onAdd())
              .backgroundColor('#1677FF')
              .fontColor('#fff')
              .width("45%")
            // Debug: 测试写入 - 会尝试写入一条示例数据并查询 DB 行数

            Button('🧪')
              .type(ButtonType.Capsule)
              .margin({ left: 8 })
              .onClick(() => {
                this.testWrite();
              })
              .width("45%")
              .backgroundColor('#00AA66')
              .fontColor('#fff')
          }
        }
      }
      .padding({ left: 16, right: 16, top: 16 });

      List({ space: 8 }) {
        ForEach(this.events, (item: MemoryItem) => {
          ListItem() {
            EventCard({
              item: item,
              deleteTargetId: $deleteTargetId,
              onEdit: (item: MemoryItem) => this.onEdit(item),
              onDelete: (id: number) => this.onDelete(id),
              onCancelDelete: () => this.cancelDelete(),
              onPerformDelete: () => this.performDelete()
            })
          }
        })
      }
      .padding({ left: 16, right: 16, bottom: 16 })
      .width('100%')
      .height('100%')
      .edgeEffect(EdgeEffect.None)
      .layoutWeight(1)
      Button('🏠')
        .type(ButtonType.Normal)
        .align(Alignment.Center)
        .width("90%")
        .onClick(() => {
          try {
            router.push({ uri: 'pages/Index' });
          } catch (e) {
            console.error('跳转首页失败', e);
          }
        })
        .backgroundColor('#FFA940')
        .fontColor('#fff')
        .margin({ left: 8 })

    }
    .width('100%')
    .height('100%')
    .background(Color.White)

    // .backgroundColor('#F7F8FA');
  }

  private triggerVibration(): void {
    try {
      // 震动50毫秒
      vibrator.vibrate(50);
    } catch (err) {
      console.error('震动失败', err);
    }
  }

  private async loadEvents(): Promise<void> {
    try {
      const cols: string[] = ['id', 'task_name', 'finished', 'target_date'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      this.events = (rows || []).map((r: Memory) => {
        const id: number = r.id ?? 0;
        const title: string = r.title ?? '';
        // Prefer stored targetDate (milliseconds since epoch) when available and valid (>0)
        const date: number | Date | null = (typeof r.targetDate === 'number' && !isNaN(r.targetDate) && r.targetDate > 0)
          ? r.targetDate
          : null;
        const type: MemoryType = r.finished ? 'anniversary' : 'countdown';
        return { id, title, date, type } as MemoryItem;
      });
    } catch (err) {
      console.log(`加载记忆失败: ${err}`);
      this.events = [];
    }
  }

  private async onAdd(): Promise<void> {
    AppStorage.Set<number>('selectedId', 0);
    router.push({ uri: 'pages/EditMemory' });
  }

  private async onEdit(item: MemoryItem): Promise<void> {
    AppStorage.setOrCreate('selectedId', item.id);
    router.push({ uri: 'pages/EditMemory', params: { editId: item.id } });
  }

  private async onDelete(id: number): Promise<void> {
    // show confirmation UI before deleting
    this.deleteTargetId = id;
  }

  private async performDelete(): Promise<void> {
    if (!this.deleteTargetId) {
      return;
    }
    try {
      await MemoryDBUtil.deleteMemoryById('memories', this.deleteTargetId);
      this.deleteTargetId = undefined;
      await this.loadEvents();
      this.triggerVibration();
    } catch (err) {
      console.error('删除失败', err);
    }
  }

  private cancelDelete(): void {
    this.deleteTargetId = undefined;
  }

  // Debug helper: write a test row and query DB using MemDBUtils directly
  private async testWrite(): Promise<void> {
    const title = `Test ${Date.now()}`;
    try {
      // For quick verification create a test row with target_date set to tomorrow at 00:00
      const t = new Date(); t.setDate(t.getDate() + 1); t.setHours(0, 0, 0, 0);
      const tomorrowMs: number = t.getTime();
      const vb: relationalStore.ValuesBucket = makeValuesBucket(title, 0, tomorrowMs);
      const rowId: number = await MemoryDBUtil.insertMemory('memories', vb);
      console.log('testWrite: inserted rowId', rowId);
    } catch (e) {
      console.error('testWrite: DB insert failed', e);
      return;
    }

    try {
      // small delay to let DB operation complete
      await new Promise<void>((resolve) => setTimeout(resolve, 500));
      const cols: string[] = ['id', 'task_name', 'finished', 'target_date'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      console.log('testWrite: query rows:', rows);
      this.events = (rows || []).map((r: Memory) => {
        const id: number = r.id ?? 0;
        const t: string = r.title ?? '';
        const date: number | Date | null = (typeof r.targetDate === 'number' && !isNaN(r.targetDate) && r.targetDate > 0)
          ? r.targetDate
          : null;
        const type: MemoryType = r.finished ? 'anniversary' : 'countdown';
        return { id, title: t, date, type } as MemoryItem;
      });
    } catch (e) {
      console.error('testWrite: query failed', e);
    }
  }
}

@Component
struct EventCard {
  @Prop item: MemoryItem;
  @Link deleteTargetId: number | undefined;
  onEdit: (item: MemoryItem) => void = () => {};
  onDelete: (id: number) => void = () => {};
  onCancelDelete: () => void = () => {};
  onPerformDelete: () => void = () => {};

  private formatDate(d: DateLike): string {
    return formatDateUtil(d);
  }

  private triggerVibration(): void {
    try {
      vibrator.vibrate(50);
    } catch (err) {
      console.error('震动失败', err);
    }
  }

  build() {
    Row({ space: 12 }) {
      Column() {
        // Title turns red when this item is pending deletion
        Text(this.item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.deleteTargetId === this.item.id ? '#FF4D4F' : '#111');
        Text(this.formatDate(this.item.date)).fontSize(12).fontColor('#666');
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // If this item is pending deletion, show inline confirm/cancel
      if (this.deleteTargetId === this.item.id) {
        Row({ space: 8 }) {
          Button('❌')
            .type(ButtonType.Normal)
            .backgroundColor('#F2F2F2')
            .onClick(() => {
              this.onCancelDelete();
              this.triggerVibration();
            })
            .width(50)
            // .borderRadius(50);
          Button('✅')
            .backgroundColor('#FF4D4F')
            .fontColor('#fff')
            .onClick(() => this.onPerformDelete())
            .width(50)
            .borderRadius(50)
            .type(ButtonType.Capsule)
        }
        .justifyContent(FlexAlign.Center)

      } else {
        Row() {
          Button('✍️').onClick(() => this.onEdit(this.item))
            .type(ButtonType.Capsule)
            .backgroundColor('#F2F2F2')
            .width(50)
            .borderRadius(50);
          Button('🗑️')
            .type(ButtonType.Capsule)
            .onClick(() => {
              this.onDelete(this.item.id);
              this.triggerVibration();
            })
            .backgroundColor('#FF7A45')
            .fontColor('#fff')
            .width(50)
            .borderRadius(50)
        }
        .justifyContent(FlexAlign.Center)
      }
    }
    .padding(12)
    .backgroundColor(this.deleteTargetId === this.item.id ? '#FFF2F0' : Color.White)
    .borderRadius(10);
  }
}
