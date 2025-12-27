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
    Column() {
      // 标题与 Logo 区块
      Column() {
        Text('关于')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 8 })
          .textAlign(TextAlign.Center);

        // Logo：优先显示资源中的图片
        Image($r('app.media.hixy_logo_old'))
          .width('60%')
          .height(100)
          .margin({ top: 8, bottom: 18 })
          .borderRadius(8)
          .objectFit(ImageFit.Contain);
      }

      // 信息卡片（开发者信息）
      this.InfoCard();

      // 底部版权与备案信息
      Column() {
        Text(this.copyright)
          .fontSize(12)
          .fontColor('#999')
          .margin({ bottom: 4 });
        Text(this.ICPnumber)
          .fontSize(12)
          .fontColor('#999');
      }
      .margin({ top: 18 });

      // 开发人员模式入口（小字灰色，放在最底部）
      Column() {
        Text('开发人员模式')
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 10 })
          .onClick(() => {
            try { router.push({ uri: 'pages/ManageMemories' }); } catch (e) { this.toast('跳转失败'); }
          });
      }
      .margin({ top: 8 });
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#f5f5f5')
    // .backgroundColor(Color.Pink)
    // .backgroundColor('#f5f5f5');
  }

  // 信息卡片：使用 Row 两端对齐展示标签和值，清晰可读
  @Builder
  InfoCard() {
    Column() {
      Text('开发者信息')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Start)
        .width('100%')
        .margin({ bottom: 12 });

      Row() {
        Text('开发团队').fontSize(14).fontColor('#666');
        Text(this.developer).fontSize(14).fontColor('#333');
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 10 });

      Row() {
        Text('联系邮箱').fontSize(14).fontColor('#666');
        Text(this.email).fontSize(14).fontColor('#0A59F7')
          .onClick(() => { this.toast(this.email); });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 10 });

      Row() {
        Text('GitHub').fontSize(14).fontColor('#666');
        Text('github.com/hiyuey3').fontSize(14).fontColor('#0A59F7')
          .onClick(() => { this.toast('打开 github.com/hiyuey3'); });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 10 });

      Row() {
        Text('应用版本').fontSize(14).fontColor('#666');
        Text(this.version).fontSize(14).fontColor('#333');
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween);

      Row() {
        Text('官方网站').fontSize(14).fontColor('#666');
        Text('xyw.cx').fontSize(14).fontColor('#0A59F7')
          .onClick(() => { this.toast('打开 xyw.cx'); });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 10 });

      Row() {
        Text('微博').fontSize(14).fontColor('#666');
        Text('@小影工作室').fontSize(14).fontColor('#333')
          .onClick(() => { this.toast('打开 微博 @小影工作室'); });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 10 });

      Row() {
        Text('微信').fontSize(14).fontColor('#666');
        Text('hiyuey3').fontSize(14).fontColor('#333')
          .onClick(() => { this.toast('复制微信 hiyuey3'); });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 10 });

      Row() {
        Text('公众号').fontSize(14).fontColor('#666');
        Text('小影团队').fontSize(14).fontColor('#333')
          .onClick(() => { this.toast('关注公众号：小影团队'); });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 10 });
    }
    .width('94%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ top: 8 });
  }

}
