@Component
export struct About {
  build() {
    Column({ space: 12 }) {
      Text('关于 MyMemories')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .align(Alignment.Center)
        .margin({ top: 24 });

      Text('版本：1.0.0')
        .fontSize(14)
        .fontColor('#666')
        .align(Alignment.Center)
        .margin({ top: 8 });

      Text('这是一个简单的倒数日 & 纪念日示例应用，展示了Tabs、列表与页面跳转的用法。')
        .fontSize(14)
        .fontColor('#444')
        .padding({ left: 18, right: 18, top: 20 })
        .lineHeight(22);

      Row() {
        Button('返回')
          .type(ButtonType.Normal)
          .backgroundColor('#F2F2F2')
          .fontColor('#333')
          .onClick(() => {
            // About is presented inside the app Tabs; use bottom navigation to switch pages.
            console.warn('Use bottom navigation to return.');
          })
          .width('90%')
          .height(48);
      }
      .justifyContent(FlexAlign.Center)
      .padding({ top: 24 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.start_window_background'));
  }
}
