import MemoryStore from '../store/MemoryStore';
import { MemoryType, MemoryItem } from '../types/MemoryTypes';
import router from '@system.router';

@Component
export struct EditMemory {
  @State memoryId: number | undefined = undefined;
  @State title: string = '';
  @State date: Date = new Date();
  @State type: 'countdown' | 'anniversary' = 'countdown';

  onInit(): void {
    const id = MemoryStore.getSelected();
    if (id) this.load(id);
  }

  private load(id: number): void {
    const ev = MemoryStore.getEventById(id);
    if (!ev) return;
    this.memoryId = ev.id;
    this.title = ev.title;
    this.date = new Date(ev.date);
    this.type = ev.type;
  }

  private save(): void {
    if (!this.memoryId) return;
    MemoryStore.updateEvent({ id: this.memoryId, title: this.title.trim(), date: new Date(this.date), type: this.type });
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
