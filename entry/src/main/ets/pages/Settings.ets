import promptAction from '@ohos.promptAction';

@Component
export struct Settings {
  @State notifyEnabled: boolean = true;
  @State reminderDaysStr: string = '7';

  private saveSettings(): void {
    // Convert and persist (demo: in-memory). In a full app, persist to storage.
    const days = parseInt(this.reminderDaysStr, 10);
    if (isNaN(days) || days < 0) {
      try { promptAction.showToast({ message: '请输入有效的提前提醒天数' }); } catch (e) {}
      return;
    }
    // Feedback to user (simple toast)
    try {
      promptAction.showToast({ message: '设置已保存' });
    } catch (e) {}
  }

  private resetDefaults(): void {
    this.notifyEnabled = true;
    this.reminderDaysStr = '7';
    try {
      promptAction.showToast({ message: '已恢复默认设置' });
    } catch (e) {}
  }

  build() {
    Column({ space: 18 }) {
      // Header
      Text('设置')
        .fontSize(22)
        .fontWeight(FontWeight.Medium)
        .fontColor('#111')
        .align(Alignment.Center)
        .margin({ top: 18 });

      // Avatar / photo area (display only for now)
      Column() {
        Image($r('app.media.background'))
          .width('120px')
          .height('120px')
          .objectFit(ImageFit.Cover)
          .borderRadius(60)
          .align(Alignment.Center);
        Row({ space: 12 }) {
          Button('更换合照')
            .onClick(() => {
              // Placeholder: implement image picker in future
              try { promptAction.showToast({ message: '更换合照功能暂未实现' }); } catch (e) {}
            });
        }
        .justifyContent(FlexAlign.Center)
      }
      .padding({ top: 6, bottom: 6 })

      // Divider
      Divider().height(1).backgroundColor('#EEEEEE');

      // Notification toggle
      Row({ space: 12 }) {
        Text('提醒通知').fontSize(16).fontColor('#111').align(Alignment.Center);
        Toggle({ type: ToggleType.Switch, isOn: this.notifyEnabled })
          .onChange((v: boolean) => this.notifyEnabled = v);
      }

      // Reminder days input
      Column({ space: 6 }) {
        Text('提前提醒天数').fontSize(14).fontColor('#666');
        TextInput({ placeholder: '例如：7', text: this.reminderDaysStr })
          .onChange((v: string) => this.reminderDaysStr = v);
      }

      // Action buttons
      Row({ space: 12 }) {
        Button('保存')
          .type(ButtonType.Capsule)
          .backgroundColor('#1677FF')
          .fontColor('#fff')
          .onClick(() => this.saveSettings())
          .width('48%');
        Button('恢复默认')
          .backgroundColor('#F2F2F2')
          .fontColor('#333')
          .onClick(() => this.resetDefaults())
          .width('48%');
      }

      // About
      Column({ space: 4 }) {
        Text('关于 Hixy_MyMemories').fontSize(14).fontColor('#111');
        Text('版本：Demo').fontSize(12).fontColor('#888');
      }

      Blank().height('20px');

      Text('提示：部分功能为示例占位，需在后续版本中实现完整逻辑。')
        .fontSize(12).fontColor('#999').align(Alignment.Center);
    }
    .padding({ left: 18, right: 18 })
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}
