import router from '@system.router';
import { MemoryItem, MemoryType } from '../types/MemoryTypes';
import promptAction from '@ohos.promptAction';
import { MemoryDBUtil, Memory } from '../utils/MemDBUtils';
import { relationalStore } from '@kit.ArkData';

@Entry
@Component
export struct ManageMemories {
  @State events: MemoryItem[] = [];
  @State deleteTargetId: number | undefined = undefined;

  // no MemoryStore subscription; refresh from DB on lifecycle hooks

  onInit(): void {
    // Load from DB at start
    this.loadEvents();
  }

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
          Row(){
          Text('管理记忆')
            .fontSize(20)
            .width('50%')
            .fontWeight(FontWeight.Bold)
            Button('🏠')
              .type(ButtonType.Capsule)
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
          Blank().margin({bottom: 8});
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
            Row({ space: 12 }) {
              Column() {
                Text(item.title).fontSize(16).fontWeight(FontWeight.Medium);
                Text(this.formatDate(item.date)).fontSize(12).fontColor('#666');
              }
              .layoutWeight(1)

              // If this item is pending deletion, show inline confirm/cancel
              if (this.deleteTargetId === item.id) {
                Row({ space: 8 }) {
                  Button('❌')
                    .backgroundColor('#F2F2F2')
                    .onClick(() => this.cancelDelete())
                    .width(80).borderRadius(5);
                  Button('✅')
                    .backgroundColor('#FF4D4F')
                    .fontColor('#fff')
                    .onClick(() => this.performDelete())
                    .width(80)
                    .borderRadius(5)
                }
                .justifyContent(FlexAlign.Center)
              } else {
                Row() {
                  Button('✍️').onClick(() => this.onEdit(item)).backgroundColor('#F2F2F2').borderRadius(50);
                  Button('🗑️')
                    .onClick(() => this.onDelete(item.id))
                    .backgroundColor('#FF7A45')
                    .fontColor('#fff')
                    .borderRadius(50);
                }
                .justifyContent(FlexAlign.Center)
              }
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
        return {
          id,
          title,
          date,
          type
        } as MemoryItem;
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
      try {
        promptAction.showToast({ message: '无法跳转到新增页面' });
      } catch (e) {
      }
      console.error('跳转 AddMemory 失败', e);
    }
  }

  private async onEdit(item: MemoryItem): Promise<void> {
    try {
      // set AppStorage first (reliable read) then navigate to EditMemory
      try {
        AppStorage.Set<number>('selectedId', item.id);
      } catch (e) {
      }
      try {
        promptAction.showToast({ message: `跳转编辑页面 id=${item.id}` });
      } catch (e) {
      }
      try {
        // small delay to allow AppStorage propagation on some runtimes
        setTimeout(() => {
          try {
            router.push({ uri: 'pages/EditMemory' });
          } catch (pushErr) {
            console.error('router.push failed', pushErr);
          }
        }, 120);
      } catch (e) {
        try {
          router.push({ uri: 'pages/EditMemory' });
        } catch (pushErr) {
          console.error('router.push failed', pushErr);
        }
      }
    } catch (e) {
      try {
        promptAction.showToast({ message: '无法跳转到编辑页面' });
      } catch (e) {
      }
      console.error('跳转 EditMemory 失败', e);
    }
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
      try {
        promptAction.showToast({ message: '已删除' });
      } catch (e) {
      }
    } catch (err) {
      console.error('删除失败', err);
      try {
        promptAction.showToast({ message: '删除失败' });
      } catch (e) {
      }
    }
  }

  private cancelDelete(): void {
    this.deleteTargetId = undefined;
  }

  private formatDate(d: Date): string {
    try {
      const y = d.getFullYear();
      const m = `${d.getMonth() + 1}`.padStart(2, '0');
      const day = `${d.getDate()}`.padStart(2, '0');
      return `${y}-${m}-${day}`;
    } catch (e) {
      return ''
    }
  }

  // Debug helper: write a test row and query DB using MemDBUtils directly
  private async testWrite(): Promise<void> {
    const title = `Test ${Date.now()}`;
    try {
      const vb: relationalStore.ValuesBucket = { task_name: title, finished: 0 } as relationalStore.ValuesBucket;
      const rowId: number = await MemoryDBUtil.insertMemory('memories', vb);
      if (rowId && rowId > 0) {
        try {
          promptAction.showToast({ message: `写入成功 id=${rowId}` });
        } catch (e) {
        }
      }
    } catch (e) {
      console.error('testWrite: DB insert failed', e);
      try {
        promptAction.showToast({ message: '写入失败 (DB insert)' });
      } catch (e2) {
      }
      return;
    }

    try {
      // small delay to let DB operation complete
      await new Promise<void>((resolve) => setTimeout(resolve, 500));
      const cols: string[] = ['id', 'task_name', 'finished'];
      const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
      const cnt = rows ? rows.length : 0;
      try {
        promptAction.showToast({ message: `测试写入完成，DB 行数: ${cnt}` });
      } catch (e) {
      }
      console.log('testWrite: query rows:', rows);
      // refresh UI from DB rows
      this.events = (rows || []).map((r: Memory) => {
        const id: number = r.id ?? 0;
        const t: string = r.title ?? '';
        const date: Date = new Date();
        const type: MemoryType = r.finished ? 'anniversary' : 'countdown';
        return {
          id,
          title: t,
          date,
          type
        } as MemoryItem;
      });
    } catch (e) {
      console.error('testWrite: query failed', e);
      try {
        promptAction.showToast({ message: '查询失败' });
      } catch (e2) {
      }
    }
  }
}
