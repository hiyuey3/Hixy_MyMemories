import { MemoryType } from '../types/MemoryTypes';
import router from '@system.router';
import { MemoryDBUtil, Memory } from '../utils/MemDBUtils';
import { relationalStore } from '@kit.ArkData';

@Component
export struct EditMemory {
  @State memoryId: number | undefined = undefined;
  @State title: string = '';
  @State date: Date = new Date();
  @State type: MemoryType = 'countdown';

  onInit(): void {
    const id = AppStorage.Get<number>('selectedId');
    if (id) this.load(id);
  }

  private async load(id: number): Promise<void> {
    try {
      const cols: string[] = ['id', 'task_name', 'finished'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      const row = (rows || []).find(r => (r.id ?? 0) === id);
      if (!row) return;
      this.memoryId = row.id ?? id;
      this.title = row.title ?? '';
      this.date = new Date();
      this.type = row.finished ? 'anniversary' : 'countdown';
    } catch (e) {
      console.error('EditMemory.load failed', e);
    }
  }

  private async save(): Promise<void> {
    if (!this.memoryId) return;
    try {
      const vb: relationalStore.ValuesBucket = { task_name: this.title.trim(), finished: this.type === 'anniversary' ? 1 : 0 } as relationalStore.ValuesBucket;
      await MemoryDBUtil.updateMemoryById('memories', this.memoryId, vb);
    } catch (e) {
      console.error('EditMemory.save update failed', e);
    }
    try { router.back(); } catch (e) { console.warn(e); }
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
