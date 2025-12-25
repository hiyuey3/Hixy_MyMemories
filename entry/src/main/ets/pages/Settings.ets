import promptAction from '@ohos.promptAction';
import router from '@system.router';
@Component
export struct Settings {
  @State notifyEnabled: boolean = true;
  @State reminderDaysStr: string = '7';

  // Small helper to avoid scattered try/catch
  private toast(msg: string): void {
    try { promptAction.showToast({ message: msg }); } catch (_) {}
  }

  private saveSettings(): void {
    const days = Number.parseInt(this.reminderDaysStr, 10);
    if (!Number.isFinite(days) || days < 0) {
      this.toast('请输入有效的提前提醒天数');
      return;
    }
    // Persist demo: AppStorage (can be replaced with real storage later)
    AppStorage.Set<boolean>('notifyEnabled', this.notifyEnabled);
    AppStorage.Set<number>('reminderDays', days);
    this.toast('设置已保存');
  }

  private resetDefaults(): void {
    this.notifyEnabled = true;
    this.reminderDaysStr = '7';
    AppStorage.Delete('notifyEnabled');
    AppStorage.Delete('reminderDays');
    this.toast('已恢复默认设置');
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
            .onClick(() => this.toast('更换合照功能暂未实现'));
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
          .onChange((v: string) => this.reminderDaysStr = v.trim());
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
