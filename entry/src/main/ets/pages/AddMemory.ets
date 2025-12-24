import MemoryStore from '../store/MemoryStore';
import router from '@system.router';

type MemoryType = 'countdown' | 'anniversary';
interface MemoryItem { id: number; title: string; date: Date; type: MemoryType; note?: string }
@Entry
@Component
export struct AddMemory {
  @State title: string = '';
  @State date: Date = new Date();
  @State type: MemoryType = 'countdown';

  private saveAndBack(): void {
    if (!this.title.trim()) return; // require title
    const item: MemoryItem = {
      id: Date.now(),
      title: this.title.trim(),
      date: new Date(this.date),
      type: this.type
    };
    MemoryStore.addEvent(item);
    try {
      router.back();
    } catch (e) {
      // fallback: nothing (user can press back)
      console.warn('router.back failed', e);
    }
  }

  build() {
    Column({ space: 12 }) {
      Text('新增事件').fontSize(20).fontWeight(FontWeight.Bold).align(Alignment.Center).margin({ top: 20 });
      TextInput({ placeholder: '标题', text: this.title }).onChange((v: string) => this.title = v);
      Row({ space: 10 }) {
        Text('类型').fontSize(14).fontColor('#666');
        Toggle({ type: ToggleType.Button, isOn: this.type === 'countdown' })
          .onChange((v: boolean) => this.type = v ? 'countdown' : 'anniversary');
        Text(this.type === 'countdown' ? '倒数日' : '纪念日').fontSize(14).fontColor('#666');
      }
      Column({ space: 6 }) {
        Text('日期').fontSize(14).fontColor('#666');
        DatePicker({ start: new Date('2000-01-01'), end: new Date('2100-12-31'), selected: this.date })
          .onDateChange((d: Date) => this.date = d);
      }
      Row({ space: 12 }) {
        Button('取消').backgroundColor('#F2F2F2').onClick(() => { try { router.back(); } catch(e) { console.warn(e); } }).width('48%');
        Button('保存').type(ButtonType.Capsule).backgroundColor('#1677FF').fontColor('#fff').onClick(() => this.saveAndBack()).width('48%');
      }
    }
    .width('100%')
    .height('100%')
    .padding(18)
  }
}
