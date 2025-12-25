import { MemoryItem, MemoryType } from '../types/MemoryTypes';
import router from '@system.router';
import { GenericRouterPushParam } from '../types/NavigationTypes';
import { MemoryDBUtil, Memory } from '../utils/MemDBUtils';

@Component
export struct EventDetail {
  @State itemId: number | undefined = undefined;
  @State item: MemoryItem | undefined = undefined;
  private unsub: (() => void) | null = null;

  // 生命周期：初始化时从 store 取出被选中的事件
  onInit(): void {
    this.itemId = AppStorage.Get<number>('selectedId');
    this.refresh();
    this.unsub = MemoryDBUtil.subscribe(() => this.refresh());
  }

  // 页面出现时强制重查（并做一次短延迟兜底）
  aboutToAppear(): void {
    this.refresh(true);
  }

  onDestroy(): void {
    if (this.unsub) { this.unsub(); this.unsub = null; }
  }

  private async refresh(delayed: boolean = false): Promise<void> {
    if (!this.itemId) return;
    await this.loadFromDb(this.itemId);
    if (delayed) setTimeout(() => { if (this.itemId) this.loadFromDb(this.itemId!); }, 300);
  }

  private async loadFromDb(id: number): Promise<void> {
    const cols: string[] = ['id', 'task_name', 'finished'];
    const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
    const row = rows.find(r => (r.id ?? 0) === id);
    if (!row) return;
    const type: MemoryType = row.finished ? 'anniversary' : 'countdown';
    this.item = { id: row.id ?? id, title: row.title ?? '', date: new Date(), type } as MemoryItem;
  }

  // 跳转到编辑页面（保持简单：仅传入 uri）
  private goEdit(): void {
    if (!this.itemId) return;
    const param: GenericRouterPushParam = { uri: 'pages/EditMemory' };
    router.push(param);
  }

  // 删除当前事件并返回上一级
  private async doDelete(): Promise<void> {
    if (!this.itemId) return;
    await MemoryDBUtil.deleteMemoryById('memories', this.itemId);
    router.back();
  }

  // 渲染函数：展示事件详情或未找到提示
  build() {
    Column({ space: 12 }) {
      if (this.item) {
        // 标题
        Text(this.item.title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .align(Alignment.Center)
          .margin({ top: 24 });

        // 日期与类型
        Text(this.item.date.toDateString())
          .fontSize(14)
          .fontColor('#666')
          .align(Alignment.Center);
        Text(this.item.type === 'countdown' ? '倒数' : '纪念')
          .fontSize(14)
          .fontColor('#333')
          .align(Alignment.Center);

        // 编辑 / 删除 按钮
        Row({ space: 12 }) {
          Button('编辑').onClick(() => this.goEdit()).width('48%');
          Button('删除')
            .backgroundColor('#FF4D4F')
            .fontColor('#fff')
            .onClick(() => this.doDelete())
            .width('48%');
        }
        .padding({ top: 20 });
      } else {
        // 未找到事件时提示用户
        Text('未找到该事件')
          .fontSize(16)
          .align(Alignment.Center)
          .margin({ top: 40 });
      }
    }
    .width('100%')
    .height('100%')
    .padding(18);
  }
}
