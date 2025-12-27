// BottomTabItem: 底部 Tab 按钮渲染器
// 主要职责：
// - 根据 currentIndex 与 targetIndex 渲染选中/未选中样式
// - 触发父组件 onSelect 回调

export interface BottomTabItemProps {
  title: string;
  targetIndex: number;
  currentIndex: number;
  normalImg?: Resource;
  selectedImg?: Resource;
  onSelect: (idx: number) => void;
}

@Builder
export function BottomTabItem(props: BottomTabItemProps) {
  Column() {
    Image(props.normalImg ? (props.currentIndex === props.targetIndex ? (props.selectedImg ?? props.normalImg) : props.normalImg) : $r('app.media.hixy_logo_new'))
      .width(24)
      .height(24)
      .align(Alignment.Center);
    Text(props.title)
      .fontSize(12)
      .fontColor(props.currentIndex === props.targetIndex ? '#5A7CC2' : '#333')
      .align(Alignment.Center)
      .margin({ top: 6 });
  }
  .width('100%')
  .height(64)
  .justifyContent(FlexAlign.Center)
  .onClick(() => props.onSelect(props.targetIndex));
}
