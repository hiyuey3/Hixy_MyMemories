import { MemoryType } from '../types/MemoryTypes';
import router from '@system.router';
import { MemoryDBUtil, Memory } from '../utils/MemDBUtils';
import { relationalStore } from '@kit.ArkData';
import promptAction from '@ohos.promptAction';

@Entry
@Component
export default struct EditMemory {
  @StorageProp('selectedId') selectedId: number = 0;
  @State memoryId: number | undefined = undefined;
  @State title: string = '';
  @State date: Date = new Date();
  @State type: MemoryType = 'countdown';

  aboutToAppear(): void {
    // Priority: router params > AppStorage
    let id = this.selectedId;
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params && params['editId']) {
        id = params['editId'] as number;
      }
    } catch (e) {
      console.error('EditMemory: failed to get params', e);
    }

    if (id) {
      this.load(id);
    } else {
      // Ensure form is reset for "Add" mode
      this.memoryId = undefined;
      this.title = '';
      this.date = new Date();
      this.type = 'countdown';
    }
  }

  private async load(id: number): Promise<void> {
    try {
      console.log('EditMemory.load: requested id=', id);
      const cols: string[] = ['id', 'task_name', 'finished', 'target_date'];
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
      // Use stored target_date if present (ms timestamp), otherwise keep today's default
      if (typeof row.targetDate === 'number' && !isNaN(row.targetDate) && row.targetDate > 0) {
        this.date = new Date(Number(row.targetDate));
      } else {
        this.date = new Date();
      }
      this.type = row.finished ? 'anniversary' : 'countdown';
      try { promptAction.showToast({ message: `加载：${this.memoryId}` }); } catch (e) {}
    } catch (e) {
      console.error('EditMemory.load failed', e);
    }
  }

  private async save(): Promise<void> {
    // central navigation helper used for create-case fallback
    const navigateBack = (): void => {
      try {
        setTimeout(() => {
          try { router.back(); } catch (err) { console.warn('router.back failed', err); }
        }, 120);
      } catch (err) {
        try { router.back(); } catch (err2) { console.warn('router.back fallback failed', err2); }
      }
    }

    // Validate input
    const newTitle = (this.title || '').trim();
    if (!newTitle) { try { promptAction.showToast({ message: '标题不能为空' }); } catch (_) {}; return; }

    // Persist the user-selected date as milliseconds since epoch in 'target_date'
    const targetDateMs: number = this.date ? Number(this.date.getTime()) : Date.now();
    const vb: relationalStore.ValuesBucket = MemoryDBUtil.makeValuesBucket(newTitle, this.type === 'anniversary' ? 1 : 0, targetDateMs);
    const cols: string[] = ['id', 'task_name', 'finished'];

    try {
      // If no memoryId provided -> create new (Add mode)
      if (!this.memoryId) {
        try {
          const newRowId: number = await MemoryDBUtil.insertMemory('memories', vb);
          if (newRowId && newRowId > 0) {
            this.memoryId = newRowId;
            // mark index to reload when returning
            try { AppStorage.Set<boolean>('needsReload', true); } catch (e) {}
            try { promptAction.showToast({ message: '已保存到数据库' }); } catch (e) {}
            // Navigate to Index so lifecycle hooks can refresh lists
            try {
              router.push({ uri: 'pages/Index' });
            } catch (e) {
              navigateBack();
            }
            return;
          } else {
            try { promptAction.showToast({ message: '保存失败，请重试' }); } catch (e) {}
            return;
          }
        } catch (insErr) {
          console.error('EditMemory.save insert failed', insErr);
          try { promptAction.showToast({ message: '保存失败，请重试' }); } catch (e) {}
          return;
        }
      }

      // Otherwise attempt update flow
      const numericId = Number(this.memoryId);
      const rowsBefore: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      const found = (rowsBefore || []).find(r => (r.id ?? 0) === numericId);

      if (!found) {
        // Treat missing record as insert
        const newRowId: number = await MemoryDBUtil.insertMemory('memories', vb);
        if (newRowId && newRowId > 0) {
          this.memoryId = newRowId;
          try { promptAction.showToast({ message: `已作为新记录保存 id=${newRowId}` }); } catch (e) {}
          // mark index to reload
          try { AppStorage.Set<boolean>('needsReload', true); } catch (e) {}
          try { router.push({ uri: 'pages/Index' }); } catch (e) { navigateBack(); }
          return;
        }
      } else {
        const rowsAffected: number = await MemoryDBUtil.updateMemoryById('memories', numericId, vb);
        try { promptAction.showToast({ message: `保存：影响行 ${rowsAffected}` }); } catch (e) {}
        if (typeof rowsAffected === 'number' && rowsAffected > 0) {
          this.title = newTitle;
          await this.load(numericId);
          try { promptAction.showToast({ message: '保存成功' }); } catch (e) {}
          // After edit, go back to management view
          try { router.push({ uri: 'pages/ManageMemories' }); } catch (e) { navigateBack(); }
          return;
        }
        // fallback insert
        const newRowId: number = await MemoryDBUtil.insertMemory('memories', vb);
        if (newRowId && newRowId > 0) {
          this.memoryId = newRowId;
          try { promptAction.showToast({ message: `已作为新记录保存 id=${newRowId}` }); } catch (e) {}
          try { AppStorage.Set<boolean>('needsReload', true); } catch (e) {}
          try { router.push({ uri: 'pages/Index' }); } catch (e) { navigateBack(); }
          return;
        }
      }

      // final probe for debugging
      try {
        const rowsAfter: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
        const foundAfter = (rowsAfter || []).find(r => (r.id ?? 0) === Number(this.memoryId));
        console.log('EditMemory.save: post-save row=', JSON.stringify(foundAfter));
      } catch (qerr) { console.log('EditMemory.save: post-save query failed', qerr); }

      try { promptAction.showToast({ message: '保存操作已完成（详情见日志）' }); } catch (e) {}
    } catch (err) {
      console.error('EditMemory.save failed', err);
      try { promptAction.showToast({ message: '保存失败' }); } catch (ee) {}
    }
  }

  build() {
    Column({ space: 12 }) {
      Text(this.memoryId ? '编辑' : '新增事件').fontSize(20).fontWeight(FontWeight.Bold).align(Alignment.Center).margin({ top: 20 });
      TextInput({ placeholder: '标题', text: this.title }).onChange((v: string) => this.title = v);

      Row({ space: 10 }) {
        Text('类型').fontSize(14).fontColor('#666');
        Row({ space: 8 }) {
          Button('倒数日')
            .type(ButtonType.Capsule)
            .backgroundColor(this.type === 'countdown' ? '#1677FF' : '#F2F2F2')
            .fontColor(this.type === 'countdown' ? '#fff' : '#333')
            .onClick(() => this.type = 'countdown');
          Button('纪念日')
            .type(ButtonType.Capsule)
            .backgroundColor(this.type === 'anniversary' ? '#1677FF' : '#F2F2F2')
            .fontColor(this.type === 'anniversary' ? '#fff' : '#333')
            .onClick(() => this.type = 'anniversary');
        }
      }

      Column({ space: 6 }) {
        Text('日期').fontSize(14).fontColor('#666');
        DatePicker({ start: new Date('2000-01-01'), end: new Date('2100-12-31'), selected: this.date })
          .onDateChange((d: Date) => this.date = d);
      }

      Row({ space: 12 }) {
        Button('取消').backgroundColor('#F2F2F2').onClick(() => { try { router.back(); } catch (e) { console.warn(e); } }).width('48%');
        Button('保存').type(ButtonType.Capsule).backgroundColor('#1677FF').fontColor('#fff').onClick(() => this.save()).width('48%');
      }
    }
    .width('100%')
    .height('100%')
    .padding(18)
  }
}
