
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
      .fontColor(props.currentIndex === props.targetIndex ? '#ff4116ff' : '#333')
      .align(Alignment.Center)
      .margin({ top: 6 });
  }
  .width('100%')
  .height(64)
  .justifyContent(FlexAlign.Center)
  .onClick(() => props.onSelect(props.targetIndex));
}

