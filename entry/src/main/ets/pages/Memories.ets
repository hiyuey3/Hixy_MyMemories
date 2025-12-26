
// 已经废弃的页面
// this page is deprecated
@Component
export struct Memories {
  build() {
    Column() {
      Text('这里是记忆页面（Memories）').fontSize(20).fontColor('#111').align(Alignment.Center).margin({ top: 40 });

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}

