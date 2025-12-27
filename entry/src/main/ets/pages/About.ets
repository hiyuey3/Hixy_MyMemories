import promptAction from '@ohos.promptAction';
import router from '@system.router';
@Component
export struct About {
  // 基本信息（可根据发布流程从包信息自动注入）
  @State version: string = "v1.0.0";
  @State copyright: string = "© 2025 小影工作室版权所有";
  @State ICPnumber: string = "闽ICP备2021006383号";
  @State developer: string = "小影团队";
  @State email: string = "hi@xyw.cx";
  private toast(msg: string): void {
    try { promptAction.showToast({ message: msg }); } catch (_) {}
  }

  // 主渲染函数：页面结构清晰，顶部为标题与 Logo，中部为信息卡片，底部为版权信息
  build() {
    Column({ space: 12 }) {
      // Top card with logo and title
      Column({ space: 8 }) {
        Blank()
          .height(16)
        Column() {
          Image($r('app.media.hixy_logo_old'))
            .width(88)
            .height(88)
            .borderRadius(44)
            .objectFit(ImageFit.Cover)
            .margin({ top: 18 });
          Text('MyMemories')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111')
            .margin({ top: 8 });
          Text(this.version)
            .fontSize(12)
            .fontColor('#888')
            .margin({ top: 2, bottom: 12 });
          // Logo copyright line
          Text('Logo © IGE')
            .fontSize(11)
            .fontColor('#9AA0A6')
            .margin({ bottom: 6 });
        }
        .alignItems(HorizontalAlign.Center);
      }

      // 信息卡片（开发者信息）
      this.InfoCard();

      // 版权与备案（淡化）
      Column() {
        Text(this.copyright)
          .fontSize(12)
          .fontColor('#9AA0A6');
        Text(this.ICPnumber)
          .fontSize(12)
          .fontColor('#9AA0A6')
          .margin({ top: 4 });
      }
      .alignItems(HorizontalAlign.Center);

      // 开发人员模式入口（非常小的灰色字，防误触）
      Column() {
        Text('开发人员模式')
          .fontSize(11)
          .fontColor('#B0B6BB')
          .margin({ top: 16, bottom: 20 })
          .onClick(() => {
            try { router.push({ uri: 'pages/DeveloperMode' }); } catch (e) { this.toast('跳转失败'); }
          });
      }
      .alignItems(HorizontalAlign.Center);
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F7F8FA');
  }

  // 信息卡片：使用 Row 两端对齐展示标签和值，清晰可读
  @Builder
  InfoCard() {
    Column() {
      Text('开发者信息')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })
        .fontColor('#111');

      this.InfoRow('开发团队', this.developer);
      Divider().height(1).backgroundColor('#F0F2F4');
      this.InfoRow('联系邮箱', this.email, '#0A59F7', () => { this.toast(this.email); });
      Divider().height(1).backgroundColor('#F0F2F4');
      this.InfoRow('GitHub', 'github.com/hiyuey3', '#0A59F7', () => { this.toast('打开 github.com/hiyuey3'); });
      Divider().height(1).backgroundColor('#F0F2F4');
      this.InfoRow('官方网站', 'xyw.cx', '#0A59F7', () => { this.toast('打开 xyw.cx'); });
      Divider().height(1).backgroundColor('#F0F2F4');
      // 官方文档
      this.InfoRow('官方文档', 'doc.5i03.cn', '#0A59F7', () => { this.toast('打开 doc.5i03.cn'); });
      Divider().height(1).backgroundColor('#F0F2F4');
      this.InfoRow('微信公众号', '小影团队');
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ top: 8 });
  }

  @Builder
  private InfoRow(label: string, value: string, valueColor: string = '#333', onClick?: () => void) {
    Row({ space: 8 }) {
      Text(label).fontSize(13).fontColor('#7E8589');
      Text(value).fontSize(13).fontColor(valueColor).onClick(() => { if (onClick) onClick(); });
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ top: 8, bottom: 8 });
  }
}
