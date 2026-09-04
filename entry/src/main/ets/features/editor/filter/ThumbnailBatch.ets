import { FilterPreset } from './FilterModels';

/** 逐张发布缩略图；资源缺失只影响对应预设，不丢弃已经完成的结果。 */
export async function renderThumbnailBatch<T>(
  presets: FilterPreset[], render: (preset: FilterPreset) => Promise<T | undefined>,
  onReady: (preset: FilterPreset, result: T) => void,
  onUnavailable: (preset: FilterPreset) => void, isActive: () => boolean
): Promise<void> {
  for (const preset of presets) {
    if (!isActive()) {
      return;
    }
    let result: T | undefined = undefined;
    try {
      result = await render(preset);
    } catch (_err) {
      // 下方将失败发布给 UI；不记录图片路径或用户内容。
    }
    if (!isActive()) {
      return;
    }
    if (result !== undefined) {
      onReady(preset, result);
    } else {
      onUnavailable(preset);
    }
    // 让出宏任务事件循环，确保 ArkUI 能及时渲染当前缩略图帧并流畅响应手势，防止界面卡死
    await new Promise<void>((resolve) => setTimeout(resolve, 0));
  }
}
