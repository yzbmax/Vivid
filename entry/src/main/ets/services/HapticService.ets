import { vibrator } from '@kit.SensorServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'HapticService';

/**
 * 触感反馈服务：为关键交互提供线性马达微震动。
 * 包含防御降级逻辑，在模拟器或关闭震动的设备上静默忽略。
 */
export class HapticService {
  private static lastTickTime: number = 0;

  /**
   * 触发轻微顿挫震动（经过 0 刻度、吸附对齐时使用）
   * 防抖限制：最短间隔 80ms
   */
  static triggerTick(): void {
    const now = Date.now();
    if (now - HapticService.lastTickTime < 80) {
      return;
    }
    HapticService.lastTickTime = now;

    try {
      vibrator.startVibration(
        { type: 'time', duration: 15 },
        { id: 0, usage: 'touch' }
      ).catch((err: Object) => {
        hilog.debug(0x0000, TAG, 'triggerTick failed: %{public}s', JSON.stringify(err));
      });
    } catch (_err) {
      // 容错降级
    }
  }

  /**
   * 触发扎实触感震动（双击归零、落印钤盖、操作完成时使用）
   */
  static triggerImpact(): void {
    try {
      vibrator.startVibration(
        { type: 'time', duration: 35 },
        { id: 0, usage: 'touch' }
      ).catch((err: Object) => {
        hilog.debug(0x0000, TAG, 'triggerImpact failed: %{public}s', JSON.stringify(err));
      });
    } catch (_err) {
      // 容错降级
    }
  }
}
