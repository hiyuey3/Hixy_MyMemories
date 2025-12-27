// 编辑/新增页面：表单与持久化 / Edit & Add form with persistence
// 主要职责：加载指定事件、表单编辑、保存到数据库
// 详细注释见各函数实现与类型定义
import { MemoryType } from '../types/MemoryTypes';
import router from '@system.router';
import { MemoryDBUtil, Memory, makeValuesBucket } from '../utils/MemDBUtils';
import { relationalStore } from '@kit.ArkData';

@Entry
@Component
export default struct EditMemory {
  @StorageProp('selectedId') selectedId: number = 0;
  @State memoryId: number | undefined = undefined;
  @State title: string = '';
  @State date: Date = new Date();
  @State type: MemoryType = 'countdown';
  @State content: string = '';

  aboutToAppear(): void {
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
      // 重置为新增模式 / reset for add mode
      this.memoryId = undefined;
      this.title = '';
      this.date = new Date();
      this.type = 'countdown';
      AppStorage.Set<number>('selectedId', 0);
    }
  }

  build() {
    Column({ space: 12 }) {
      Text(this.memoryId ? '编辑' : '新增事件')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .align(Alignment.Center)
        .margin({ top: 20 });
      Row({ space: 10 }) {
        Column(){
          Text('类型').fontSize(14).fontColor('#666').margin({bottom:5});
          Row({ space: 8 }) {
            Button('倒数日')
              .type(ButtonType.Normal)
              .width('45%')
              .backgroundColor(this.type === 'countdown' ? '#5A7CC2' : '#F2F2F2')
              .fontColor(this.type === 'countdown' ? '#fff' : '#333')
              .onClick(() => this.type = 'countdown');
            Button('纪念日')
              .type(ButtonType.Normal)
              .width('45%')
              .backgroundColor(this.type === 'anniversary' ? '#FF7F50' : '#F2F2F2')
              .fontColor(this.type === 'anniversary' ? '#fff' : '#333')
              .onClick(() => this.type = 'anniversary');
          }
        }
      }
      TextInput({ placeholder: '标题', text: this.title }).onChange((v: string) => this.title = v);


      // Move note above date picker
      Column({ space: 6 }) {
        Text('备注').fontSize(14).fontColor('#666');
        TextArea({ placeholder: '填写备注...', text: this.content })
          .onChange((v: string) => this.content = v)
          .height(120)
          .borderColor('#DDD')
          .borderWidth(1)
          .borderRadius(6);
      }

      Column({ space: 6 }) {
        Text('日期').fontSize(14).fontColor('#666');
        DatePicker({ start: new Date('2000-01-01'), end: new Date('2100-12-31'), selected: this.date })
          .onDateChange((d: Date) => this.date = d);
      }


      // 占位将按钮推到底部
      Blank().layoutWeight(1);

      // Bottom actions pinned to page bottom: Delete (if editing) + Cancel/Save
      Column() {
        // if (this.memoryId) {
        //   Button('删除')
        //     .type(ButtonType.Capsule)
        //     .backgroundColor('#FFF5F5')
        //     .fontColor('#FF4D4F')
        //     .borderRadius(8)
        //     .height(40)
        //     .onClick(() => this.delete());
        // }
        Row({ space: 12 }) {
          Button('取消')
            .backgroundColor('#F2F2F2')
            .fontColor('#333')
            .height(44)
            .onClick(() => {
              try {
                router.back();
              } catch (e) {
                console.warn(e);
              }
            })
            .width('48%');
          Button('保存')
            .type(ButtonType.Capsule)
            .backgroundColor('#1677FF')
            .fontColor('#fff')
            .onClick(() => this.save())
            .width('48%');
        }
        .margin({ top: 12 });
      }
      .width('100%');
    }
    .width('100%')
    .height('100%')
    .padding(18);
  }

  private async load(id: number): Promise<void> {
    console.log('EditMemory.load: requested id=', id);
    // 读取并填充表单 / hydrate form from DB row
    const cols: string[] = ['id', 'task_name', 'finished', 'target_date', 'content'];
    const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
    const row = (rows || []).find(r => (r.id ?? 0) === id);
    if (!row) {
      console.warn('EditMemory.load: no row found for id=', id);
      return;
    }
    this.memoryId = row.id ?? id;
    this.title = row.title ?? '';
    if (typeof row.targetDate === 'number' && !isNaN(row.targetDate) && row.targetDate > 0) {
      this.date = new Date(Number(row.targetDate));
    } else {
      this.date = new Date();
    }
    this.type = row.finished ? 'anniversary' : 'countdown';
    this.content = row.content ?? '';
  }

  private async save(): Promise<void> {
    const newTitle = (this.title || '').trim();
    if (!newTitle) {
      return;
    }

    // 序列化日期为毫秒时间戳 / persist date as ms
    const targetDateMs: number = this.date ? Number(this.date.getTime()) : Date.now();
    const vb: relationalStore.ValuesBucket =
      makeValuesBucket(newTitle, this.type === 'anniversary' ? 1 : 0, targetDateMs, this.content);
    const cols: string[] = ['id', 'task_name', 'finished'];

    if (!this.memoryId) {
      // 插入新增 / insert new
      const newRowId: number = await MemoryDBUtil.insertMemory('memories', vb);
      if (newRowId && newRowId > 0) {
        this.memoryId = newRowId;
        AppStorage.Set<boolean>('needsReload', true);
        AppStorage.Set<number>('selectedId', 0);
        try {
          router.push({ uri: 'pages/Index' });
        } catch (e) {
          try {
            router.back();
          } catch (_) {
          }
        }
        return;
      }
      return;
    }

    const numericId = Number(this.memoryId);
    const rowsBefore: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
    const found = (rowsBefore || []).find(r => (r.id ?? 0) === numericId);

    if (!found) {
      const newRowId: number = await MemoryDBUtil.insertMemory('memories', vb);
      if (newRowId && newRowId > 0) {
        this.memoryId = newRowId;
        AppStorage.Set<boolean>('needsReload', true);
        AppStorage.Set<number>('selectedId', 0);
        try {
          router.push({ uri: 'pages/Index' });
        } catch (e) {
          try {
            router.back();
          } catch (_) {
          }
        }
        return;
      }
    } else {
      const rowsAffected: number = await MemoryDBUtil.updateMemoryById('memories', numericId, vb);
      if (typeof rowsAffected === 'number' && rowsAffected > 0) {
        // 更新成功后返回上一个页面并触发重载
        this.title = newTitle;
        await this.load(numericId);
        AppStorage.Set<number>('selectedId', 0);
        AppStorage.Set<boolean>('needsReload', true);
        try {
          router.back();
        } catch (e) {
          console.warn(e);
        }
        return;
      }
      const newRowId: number = await MemoryDBUtil.insertMemory('memories', vb);
      if (newRowId && newRowId > 0) {
        this.memoryId = newRowId;
        AppStorage.Set<boolean>('needsReload', true);
        AppStorage.Set<number>('selectedId', 0);
        try {
          router.push({ uri: 'pages/Index' });
        } catch (e) {
          try {
            router.back();
          } catch (_) {
          }
        }
        return;
      }
    }

    try {
      const rowsAfter: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      const foundAfter = (rowsAfter || []).find(r => (r.id ?? 0) === Number(this.memoryId));
      console.log('EditMemory.save: post-save row=', JSON.stringify(foundAfter));
    } catch (_) {
    }

  }

  // 删除当前事件（仅在编辑模式下可用）
  private async delete(): Promise<void> {
    if (!this.memoryId) {
      try {
        router.back();
      } catch (_) {
      }
      return;
    }
    const numericId = Number(this.memoryId);
    try {
      const rowsDeleted: number = await MemoryDBUtil.deleteMemoryById('memories', numericId);
      if (typeof rowsDeleted === 'number' && rowsDeleted > 0) {
        AppStorage.Set<boolean>('needsReload', true);
        AppStorage.Set<number>('selectedId', 0);
        try {
          router.back();
        } catch (_) {
        }
        return;
      }
    } catch (e) {
      console.warn('Delete failed', e);
    }
    // 回退兜底
    try {
      router.back();
    } catch (_) {
    }
  }
}
