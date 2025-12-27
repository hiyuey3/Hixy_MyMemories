import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';

const DOMAIN = 0x0000;

/**
 * EntryBackupAbility: 负责应用数据的备份与恢复
 * 继承自 BackupExtensionAbility，系统在备份/恢复操作时会调用此 Ability
 */
export default class EntryBackupAbility extends BackupExtensionAbility {
  /**
   * 备份数据时触发
   */
  async onBackup() {
    hilog.info(DOMAIN, 'testTag', 'onBackup ok');
    await Promise.resolve();
  }

  /**
   * 恢复数据时触发
   * @param bundleVersion 恢复时的包版本信息
   */
  async onRestore(bundleVersion: BundleVersion) {
    hilog.info(DOMAIN, 'testTag', 'onRestore ok %{public}s', JSON.stringify(bundleVersion));
    await Promise.resolve();
  }
}