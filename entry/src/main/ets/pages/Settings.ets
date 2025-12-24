@Component
export struct Settings {
  build() {
    Column() {
      Text('这里是设置页面（Settings）').fontSize(20).fontColor('#111').align(Alignment.Center).margin({ top: 40 });
      // TODO: 将设置相关逻辑移到这里
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}

