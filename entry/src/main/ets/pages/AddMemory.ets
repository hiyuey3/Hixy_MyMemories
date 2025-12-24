import router from '@system.router';
import { MemoryType, MemoryItem } from '../types/MemoryTypes';
import promptAction from '@ohos.promptAction';
import { MemoryDBUtil } from '../utils/MemDBUtils';
import { relationalStore } from '@kit.ArkData';

@Entry
@Component
export struct AddMemory {
  @State title: string = '';
  @State date: Date = new Date();
  @State type: MemoryType = 'countdown';

  private async saveAndBack(): Promise<void> {
    if (!this.title.trim()) {
      try { promptAction.showToast({ message: '标题不能为空' }); } catch (e) {}
      return; // require title
    }
    const item: MemoryItem = {
      id: Date.now(),
      title: this.title.trim(),
      date: new Date(this.date),
      type: this.type
    };
    let savedToDb: boolean = false;
    // Try inserting into DB first to provide accurate feedback
    try {
      const vb: relationalStore.ValuesBucket = { task_name: item.title, finished: item.type === 'anniversary' ? 1 : 0 } as relationalStore.ValuesBucket;
      const rowId = await MemoryDBUtil.insertMemory('memories', vb);
      if (rowId && rowId > 0) {
        item.id = rowId;
        savedToDb = true;
      }
    } catch (dbErr) {
      console.log('AddMemory: DB 插入失败', dbErr);
    }

    // Feedback: only DB success acknowledged; otherwise user stays informed they need retry
    try {
      promptAction.showToast({ message: savedToDb ? '已保存到数据库' : '保存失败，请重试' });
    } catch (e) {}
    // Hint Index to refresh once when coming back
    try { AppStorage.Set<boolean>('needsReload', true); } catch (e) {}

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
        // Use two explicit buttons for better UX and compatibility
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
        Button('取消').backgroundColor('#F2F2F2').onClick(() => { try { router.back(); } catch(e) { console.warn(e); } }).width('48%');
        Button('保存').type(ButtonType.Capsule).backgroundColor('#1677FF').fontColor('#fff').onClick(() => this.saveAndBack()).width('48%');
      }
    }
    .width('100%')
    .height('100%')
    .padding(18)
  }
}
