import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { MemoryDBUtil } from '../utils/MemDBUtils';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 主窗口已创建，设置此能力的主页面
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 使用有效的 Context 初始化内存数据库，以便页面可以使用 MemoryDBUtil
    try {
      MemoryDBUtil.initMemoryDB(this.context, 'memories');
      hilog.info(DOMAIN, 'testTag', 'MemoryDB 初始化完成');
    } catch (dbErr) {
      hilog.error(DOMAIN, 'testTag', 'MemoryDB 初始化失败: %{public}s', JSON.stringify(dbErr));
    }


    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', '加载内容失败。原因: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', '成功加载内容。');
    });
  }

  onWindowStageDestroy(): void {
    // 主窗口被销毁，释放与 UI 相关的资源
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability 已被带到前台
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability 已返回后台
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}