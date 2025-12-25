import { MemoryType } from '../types/MemoryTypes';
import router from '@system.router';
import { MemoryDBUtil, Memory } from '../utils/MemDBUtils';
import { relationalStore } from '@kit.ArkData';
import promptAction from '@ohos.promptAction';

// ...existing code...

@Entry
@Component
export default struct EditMemory {
  @State memoryId: number | undefined = undefined;
  @State title: string = '';
  @State date: Date = new Date();
  @State type: MemoryType = 'countdown';

  onInit(): void {
    // Read selected id from AppStorage (preferred). Retry shortly if not present yet.
    let id: number | undefined = undefined;
    try { id = AppStorage.Get<number>('selectedId'); } catch (e) { id = undefined; }

    if (id) {
      this.load(id);
    } else {
      try {
        setTimeout(() => {
          try {
            const id2 = AppStorage.Get<number>('selectedId');
            if (id2) this.load(id2);
          } catch (e) { /* ignore delayed read errors */ }
        }, 200);
      } catch (e) { /* ignore */ }
    }
  }

  onShow(): void {
    // ensure we reload when page becomes visible
    const id = AppStorage.Get<number>('selectedId');
    if (id) {
      this.load(id);
    }
  }

  aboutToAppear(): void {
    // attempt immediate load and a short delayed retry to cover propagation delays
    const id = AppStorage.Get<number>('selectedId');
    if (id) {
      this.load(id);
      try { setTimeout(() => { const id2 = AppStorage.Get<number>('selectedId'); if (id2) this.load(id2); }, 300); } catch (e) {}
    }
  }

  private async load(id: number): Promise<void> {
    try {
      console.log('EditMemory.load: requested id=', id);
      const cols: string[] = ['id', 'task_name', 'finished'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      console.log('EditMemory.load: query returned rows count=', rows ? rows.length : 0);
      const row = (rows || []).find(r => (r.id ?? 0) === id);
      if (!row) {
        console.warn('EditMemory.load: no row found for id=', id);
        try { promptAction.showToast({ message: '未找到要编辑的记录' }); } catch (e) {}
        return;
      }
      console.log('EditMemory.load: found row=', JSON.stringify(row));
      if (!row) return;
      this.memoryId = row.id ?? id;
      this.title = row.title ?? '';
      this.date = new Date();
      this.type = row.finished ? 'anniversary' : 'countdown';
      try { promptAction.showToast({ message: `加载：${this.title}` }); } catch (e) {}
    } catch (e) {
      console.error('EditMemory.load failed', e);
    }
  }

  private async save(): Promise<void> {
    // central navigation helper
    const navigateBack = (): void => {
      try {
        setTimeout(() => {
          try { router.back(); } catch (err) { console.warn('router.back failed', err); }
        }, 120);
      } catch (err) {
        try { router.back(); } catch (err2) { console.warn('router.back fallback failed', err2); }
      }
    }

    // Ensure we have a valid id; try AppStorage as fallback
    if (!this.memoryId) {
      try { const sid = AppStorage.Get<number>('selectedId'); if (sid) this.memoryId = sid; } catch (e) { /* ignore */ }
    }

    if (!this.memoryId) { try { promptAction.showToast({ message: '无法保存：未指定记录' }); } catch (_) {}; console.warn('EditMemory.save: no memoryId'); return; }

    // Validate input
    const newTitle = (this.title || '').trim();
    if (!newTitle) { try { promptAction.showToast({ message: '标题不能为空' }); } catch (_) {}; return; }

    const numericId = Number(this.memoryId);
    const vb: relationalStore.ValuesBucket = { task_name: newTitle, finished: this.type === 'anniversary' ? 1 : 0 } as relationalStore.ValuesBucket;
    const cols: string[] = ['id', 'task_name', 'finished'];

    try {
      // Check existence
      const rowsBefore: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      const found = (rowsBefore || []).find(r => (r.id ?? 0) === numericId);

      if (!found) {
        // Insert new
        const newRowId: number = await MemoryDBUtil.insertMemory('memories', vb);
        if (newRowId && newRowId > 0) {
          this.memoryId = newRowId;
          await this.load(newRowId);
          try { promptAction.showToast({ message: `已作为新记录保存 id=${newRowId}` }); } catch (e) {}
          navigateBack();
          return;
        }
      } else {
        // Update existing
        const rowsAffected: number = await MemoryDBUtil.updateMemoryById('memories', numericId, vb);
        try { promptAction.showToast({ message: `保存：影响行 ${rowsAffected}` }); } catch (e) {}
        if (typeof rowsAffected === 'number' && rowsAffected > 0) {
          this.title = newTitle;
          await this.load(numericId);
          try { promptAction.showToast({ message: '保存成功' }); } catch (e) {}
          navigateBack();
          return;
        }
        // fallback insert
        const newRowId: number = await MemoryDBUtil.insertMemory('memories', vb);
        if (newRowId && newRowId > 0) {
          this.memoryId = newRowId;
          await this.load(newRowId);
          try { promptAction.showToast({ message: `已作为新记录保存 id=${newRowId}` }); } catch (e) {}
          navigateBack();
          return;
        }
      }

      // final probe for debugging
      try {
        const rowsAfter: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
        const foundAfter = (rowsAfter || []).find(r => (r.id ?? 0) === numericId || (this.memoryId && r.id === this.memoryId));
        console.log('EditMemory.save: post-save row=', JSON.stringify(foundAfter));
      } catch (qerr) { console.log('EditMemory.save: post-save query failed', qerr); }

      try { promptAction.showToast({ message: '保存操作已完成（详情见日志）' }); } catch (e) {}
    } catch (err) {
      console.error('EditMemory.save update failed', err);
      try { promptAction.showToast({ message: '保存失败' }); } catch (ee) {}
    }
  }

  build() {
    Column({ space: 12 }) {
      Text('编辑').fontSize(20).fontWeight(FontWeight.Bold).align(Alignment.Center).margin({ top: 20 });
      TextInput({ placeholder: '标题', text: this.title }).onChange((v: string) => this.title = v);
      Row({ space: 10 }) {
        Toggle({ type: ToggleType.Button, isOn: this.type === 'countdown' }).onChange((v: boolean) => this.type = v ? 'countdown' : 'anniversary');
        Text(this.type === 'countdown' ? '倒数日' : '纪念日');
      }
      DatePicker({ start: new Date('2000-01-01'), end: new Date('2100-12-31'), selected: this.date }).onDateChange((d: Date) => this.date = d);
      Row({ space: 12 }) {
        Button('取消').onClick(() => { try { router.back(); } catch (e) { console.warn(e); } }).width('48%');
        Button('保存').type(ButtonType.Capsule).backgroundColor('#1677FF').fontColor('#fff').onClick(() => this.save()).width('48%');
      }
    }
    .width('100%')
    .height('100%')
    .padding(18)
  }
}
