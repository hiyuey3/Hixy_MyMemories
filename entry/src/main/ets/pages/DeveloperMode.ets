// 管理页：列表、编辑、删除入口 / Management page for list/edit/delete
import router from '@system.router';
import promptAction from '@ohos.promptAction';
import { MemoryItem, MemoryType, DateLike } from '../types/MemoryTypes';
import { MemoryDBUtil, Memory, makeValuesBucket } from '../utils/MemDBUtils';
import { relationalStore } from '@kit.ArkData';
import { formatDate as formatDateUtil } from '../utils/dateUtils';
import vibrator from '@ohos.vibrator';
import pasteboard from '@ohos.pasteboard';

interface MemoryExportItem { title: string; date: number | string | null; type: MemoryType; }
interface MemoryImportItem { title?: string; date?: number | string | null; type?: string; }

@Entry
@Component
export struct ManageMemories {
  @State events: MemoryItem[] = [];
  @State deleteTargetId: number | undefined = undefined;
  @State busy: boolean = false;
  // 统一的导入/导出文本框与模式
  @State ioText: string = '';
  @State isExportMode: boolean = true;

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
    // refresh twice: immediately and after a short delay to catch recent DB commits
    this.loadEvents();
    setTimeout(() => this.loadEvents(), 300);
  }

  build() {
    Column({ space: 16 }) {
      // Header
      Column() {
        Text('管理模式')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111')
          .margin({ top: 18 });
        Text('仅在开发者指导下调试使用，慎重操作！！！')
          .fontSize(12)
          .fontColor('#9AA0A6')
          .margin({ top: 6, bottom: 6 });
      }
      .alignItems(HorizontalAlign.Center)

      // Action buttons row
      Row({ space: 10 }) {
        Button('➕ 新增测试数据')
          .type(ButtonType.Capsule)
          .backgroundColor('#1677FF')
          .fontColor('#FFFFFF')
          .onClick(() => this.testWrite())
          .layoutWeight(1)
          .height(40);

        Button('🧹 清理全部数据')
          .type(ButtonType.Capsule)
          .backgroundColor('#FF4D4F')
          .fontColor('#FFFFFF')
          .onClick(() => this.clearAll())
          .layoutWeight(1)
          .height(40);
      }
      .padding({ left: 16, right: 16 })

      Row({ space: 10 }) {
        Button('📤 导出日志')
          .type(ButtonType.Capsule)
          .backgroundColor('#00AA66')
          .fontColor('#FFFFFF')
          .onClick(() => this.exportLogs())
          .layoutWeight(1)
          .height(40);

        Button('🏠 返回首页')
          .type(ButtonType.Capsule)
          .backgroundColor('#FFA940')
          .fontColor('#FFFFFF')
          .onClick(() => router.push({ uri: 'pages/Index' }))
          .layoutWeight(1)
          .height(40);
      }
      .padding({ left: 16, right: 16 });

      // 导入 / 导出（复用一个输入框）
      Column({ space: 10 }) {
        Row({ space: 8 }) {
          // 模式切换：导出 / 导入
          Button(this.isExportMode ? '导出模式' : '切到导出')
            .type(ButtonType.Capsule)
            .backgroundColor(this.isExportMode ? '#1677FF' : '#E5E7EB')
            .fontColor(this.isExportMode ? '#FFFFFF' : '#333333')
            .height(32)
            .onClick(() => { this.isExportMode = true; });
          Button(!this.isExportMode ? '导入模式' : '切到导入')
            .type(ButtonType.Capsule)
            .backgroundColor(!this.isExportMode ? '#00AA66' : '#E5E7EB')
            .fontColor(!this.isExportMode ? '#FFFFFF' : '#333333')
            .height(32)
            .onClick(() => { this.isExportMode = false; });
          // 清空
          Button('清空')
            .type(ButtonType.Capsule)
            .backgroundColor('#F2F2F2')
            .fontColor('#333333')
            .height(32)
            .onClick(() => { this.ioText = ''; });
        }

        TextArea({ placeholder: this.isExportMode ? '导出数据 JSON（只读）' : '粘贴 JSON 数据（可编辑）', text: this.ioText })
          .enabled(!this.isExportMode)
          .height(120)
          .borderColor('#E5E7EB')
          .borderWidth(1)
          .borderRadius(8)
          .padding(10);

        Row({ space: 8 }) {
          if (this.isExportMode) {
            Button('生成导出')
              .type(ButtonType.Capsule)
              .backgroundColor('#1677FF')
              .fontColor('#FFFFFF')
              .height(36)
              .onClick(() => this.exportData());
            Button('复制')
              .type(ButtonType.Capsule)
              .backgroundColor('#4B5563')
              .fontColor('#FFFFFF')
              .height(36)
              .onClick(() => this.copyExport());
          } else {
            Button('导入数据')
              .type(ButtonType.Capsule)
              .backgroundColor('#00AA66')
              .fontColor('#FFFFFF')
              .height(36)
              .onClick(() => this.importData());
          }
        }
      }
      .padding({ left: 16, right: 16 });

      // List of events (cards)
      List({ space: 10 }) {
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
      .layoutWeight(1);

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA');
  }

  private triggerVibration(): void {
    try {
      // 震动提示 / haptic feedback
      vibrator.vibrate(50);
    } catch (err) {
      console.error('震动失败', err);
    }
  }

  private toast(msg: string): void {
    try { promptAction.showToast({ message: msg }); } catch (_) {}
  }

  // Clear all rows in DB (developer operation)
  private async clearAll(): Promise<void> {
    try {
      this.busy = true;
      const cols: string[] = ['id'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      for (const r of rows) {
        const id = r.id ?? 0;
        if (id > 0) {
          try { await MemoryDBUtil.deleteMemoryById('memories', id); } catch (_) {}
        }
      }
      await this.loadEvents();
      this.triggerVibration();
    } catch (e) {
      console.error('clearAll failed', e);
    } finally {
      this.busy = false;
    }
  }

  // Export logs stub (developer can replace with real export)
  private exportLogs(): void {
    this.toast('导出日志：已生成到应用沙箱（示例）');
  }

  // Export current events to JSON (developer convenience)
  private exportData(): void {
    const payload: MemoryExportItem[] = (this.events || []).map((e: MemoryItem): MemoryExportItem => {
      let normalizedDate: number | string | null = null;
      if (e.date instanceof Date) {
        normalizedDate = e.date.getTime();
      } else if (typeof e.date === 'number') {
        normalizedDate = e.date;
      } else if (typeof e.date === 'string') {
        normalizedDate = e.date;
      }
      return { title: e.title, date: normalizedDate, type: e.type ?? 'countdown' } as MemoryExportItem;
    });
    this.ioText = JSON.stringify(payload);
    this.toast('导出完成，可复制 JSON');
  }

  // Copy export JSON to clipboard
  private async copyExport(): Promise<void> {
    const text: string = this.ioText ?? '';
    if (!text || text.length === 0) {
      this.toast('无可复制内容');
      return;
    }
    try {
      const sysPB = pasteboard.getSystemPasteboard();
      const data = pasteboard.createPlainTextData(text);
      await sysPB.setData(data);
      this.toast('已复制到剪贴板');
    } catch (e) {
      console.error('copyExport failed', e);
      this.toast('复制失败');
    }
  }

  // Import JSON array of events and insert into DB
  private async importData(): Promise<void> {
    if (!this.ioText || this.ioText.trim().length === 0) {
      this.toast('请先粘贴 JSON 数据');
      return;
    }
    let arr: MemoryImportItem[];
    try {
      arr = JSON.parse(this.ioText) as MemoryImportItem[];
    } catch (e) {
      console.error('importData parse failed', e);
      this.toast('导入失败，检查 JSON 格式');
      return;
    }
    if (!Array.isArray(arr)) {
      this.toast('格式错误：需要数组');
      return;
    }
    let count = 0;
    for (const item of arr) {
      const title: string = (item?.title ?? '').toString().trim();
      if (!title) { continue; }
      const type: MemoryType = item?.type === 'anniversary' ? 'anniversary' : 'countdown';
      const dateVal: number | string | null | undefined = item?.date;
      let dateMs: number = Date.now();
      if (typeof dateVal === 'number' && !isNaN(dateVal)) {
        dateMs = dateVal;
      } else if (typeof dateVal === 'string' && dateVal.length > 0) {
        const parsed = Date.parse(dateVal);
        if (!isNaN(parsed)) { dateMs = parsed; }
      }
      const vb: relationalStore.ValuesBucket = makeValuesBucket(title, type === 'anniversary' ? 1 : 0, dateMs);
      try {
        await MemoryDBUtil.insertMemory('memories', vb);
        count++;
      } catch (e) { console.error('import insert failed', e); }
    }
    await this.loadEvents();
    this.toast(`导入完成，成功 ${count} 条`);
  }

  // 跳转到编辑页
  private onEdit(item: MemoryItem): void {
    AppStorage.Set<number>('selectedId', item.id);
    try { router.push({ uri: 'pages/EditMemory', params: { editId: item.id } }); } catch (_) {}
  }

  // 标记待删除项
  private onDelete(id: number): void {
    this.deleteTargetId = id;
  }

  // 取消删除
  private cancelDelete(): void {
    this.deleteTargetId = undefined;
  }

  // 确认删除
  private async performDelete(): Promise<void> {
    if (!this.deleteTargetId) { return; }
    try {
      await MemoryDBUtil.deleteMemoryById('memories', this.deleteTargetId);
      this.toast('已删除');
    } catch (e) {
      console.error('performDelete failed', e);
      this.toast('删除失败');
    } finally {
      this.deleteTargetId = undefined;
      await this.loadEvents();
    }
  }

  // 从数据库读取列表
  private async loadEvents(): Promise<void> {
    try {
      const cols: string[] = ['id', 'task_name', 'finished', 'target_date', 'content'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      this.events = (rows || []).map((r: Memory): MemoryItem => {
        const id: number = r.id ?? 0;
        const title: string = r.title ?? '';
        const date: Date | number | null = (typeof r.targetDate === 'number' && !isNaN(r.targetDate) && r.targetDate > 0)
          ? r.targetDate
          : null;
        const type: MemoryType = r.finished ? 'anniversary' : 'countdown';
        const note: string | undefined = r.content ?? undefined;
        return { id, title, date, type, note } as MemoryItem;
      });
    } catch (err) {
      console.log(`加载记忆列表失败: ${err}`);
      this.events = [];
    }
  }

  // Debug helper: write a test row and query DB using MemDBUtils directly
  private async testWrite(): Promise<void> {
    const title = `Test ${Date.now()}`;
    const t = new Date(); t.setDate(t.getDate() + 1); t.setHours(0, 0, 0, 0);
    const vb: relationalStore.ValuesBucket = makeValuesBucket(title, 0, t.getTime());
    try {
      await MemoryDBUtil.insertMemory('memories', vb);
      await new Promise<void>((resolve) => setTimeout(resolve, 500));
      await this.loadEvents();
    } catch (e) {
      console.error('testWrite failed', e);
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
