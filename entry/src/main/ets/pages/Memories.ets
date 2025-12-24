@Component
export struct Memories {
  build() {
    Column() {
      Text('这里是记忆页面（Memories）').fontSize(20).fontColor('#111').align(Alignment.Center).margin({ top: 40 });
      // TODO: 将真实记忆页面逻辑移到这里（列表、筛选等）
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}

