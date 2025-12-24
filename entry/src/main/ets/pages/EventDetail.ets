import MemoryStore from '../store/MemoryStore';
import { MemoryItem } from '../types/MemoryTypes';
import router from '@system.router';
import { GenericRouterPushParam } from '../types/NavigationTypes';

@Component
export struct EventDetail {
  // 当前选中的事件 id
  @State itemId: number | undefined = undefined;
  // 当前显示的事件对象
  @State item: MemoryItem | undefined = undefined;

  // 生命周期：初始化时从 store 取出被选中的事件
  onInit(): void {
    const id = MemoryStore.getSelected();
    this.itemId = id;
    if (id) this.item = MemoryStore.getEventById(id);
  }

  // 跳转到编辑页面（保持简单：仅传入 uri）
  private goEdit(): void {
    if (!this.itemId) return;
    const param: GenericRouterPushParam = { uri: 'pages/EditMemory' };
    try {
      router.push(param);
    } catch (e) {
      // 仅打印，不阻塞 UI
      console.warn(e);
    }
  }

  // 删除当前事件并返回上一级
  private doDelete(): void {
    if (!this.itemId) return;
    MemoryStore.deleteEvent(this.itemId);
    try {
      router.back();
    } catch (e) {
      console.warn(e);
    }
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
