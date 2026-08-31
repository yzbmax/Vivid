import { subjectSegmentation } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { SegmentationOutput, RectData, SegmentOutcome,
  DEFAULT_MAX_SUBJECT_COUNT, SEGMENTATION_TIMEOUT_MS, SegErrorCode } from '../models/SegmentationModels';
import { mattingListToWeights, validateRawMask } from '../utils/MaskDataUtils';

const TAG = 'SubjectSegmentationService';

/**
 * 主体分割服务：AI 生命周期、Core Vision 调用、结果解析、
 * SDK Error 映射、资源释放、超时与代次取消的唯一归属。
 *
 * 架构迁移（2026-08-26）：启用 enableSubjectForegroundImage=true，
 * 获取透明背景前景图用于双图 colorFilter 渲染（替代 Worker 管线）。
 *
 * 页面不得直接处理 Core Vision 返回结构——统一出口是 SegmentOutcome。
 */

/** 测试注入口（V2 §34）：单测注入 FakeAdapter 后 service 测试不依赖真机。 */
export interface SegmentationAdapter {
  init(): Promise<boolean>;
  doSegmentation(
    visionInfo: subjectSegmentation.VisionInfo,
    config: subjectSegmentation.SegmentationConfig
  ): Promise<subjectSegmentation.SegmentationResult>;
  release(): Promise<void>;
}

/** 默认适配器：直连 Core Vision Kit。 */
class DefaultSegmentationAdapter implements SegmentationAdapter {
  async init(): Promise<boolean> {
    return subjectSegmentation.init();
  }

  async doSegmentation(
    visionInfo: subjectSegmentation.VisionInfo,
    config: subjectSegmentation.SegmentationConfig
  ): Promise<subjectSegmentation.SegmentationResult> {
    return subjectSegmentation.doSegmentation(visionInfo, config);
  }

  async release(): Promise<void> {
    await subjectSegmentation.release();
  }
}

/** SegmentOutcome 已迁至 Kit-free 的 SegmentationModels（本地单测可加载），此处 re-export。 */
export { SegmentOutcome } from '../models/SegmentationModels';

export class SubjectSegmentationService {
  private adapter: SegmentationAdapter;
  private initialized: boolean = false;
  private initializing: Promise<void> | null = null;
  /** 会话代次：换图/离开页面时自增，使在途任务失效（V2 §17/§30）。 */
  private sessionGeneration: number = 0;

  constructor(adapter?: SegmentationAdapter) {
    this.adapter = (adapter !== undefined && adapter !== null)
      ? adapter : new DefaultSegmentationAdapter();
  }

  /**
   * 幂等初始化。并发调用共享同一次 init；返回 false 时映射 INIT_FAILED。
   */
  async ensureInit(): Promise<void> {
    if (this.initialized) {
      return;
    }
    if (this.initializing !== null) {
      await this.initializing;
      return;
    }
    const task = (async (): Promise<void> => {
      try {
        const ok = await this.adapter.init();
        if (!ok) {
          const failure = new Error('INIT_FAILED');
          throw failure;
        }
        this.initialized = true;
        hilog.info(0x0000, TAG, 'subject segmentation initialized');
      } finally {
        this.initializing = null;
      }
    })();
    this.initializing = task;
    await task;
  }

  /**
   * 执行分割并产出统一的 SegmentationOutput。
   *
   * 流程：ensureInit → adapter.doSegmentation（带超时）→ mattingList 转 weights
   * → RawMask 强制校验 → 构造输出。任何一步失败都归并为对应 SegErrorCode，
   * 不向页面泄漏 SDK 结构。
   */
  async segment(
    pixelMap: image.PixelMap,
    maxCount: number = DEFAULT_MAX_SUBJECT_COUNT
  ): Promise<SegmentOutcome> {
    const myGeneration = this.sessionGeneration;

    try {
      await this.ensureInit();
    } catch (_err) {
      return SubjectSegmentationService.errorOut('INIT_FAILED');
    }
    if (myGeneration !== this.sessionGeneration) {
      return SubjectSegmentationService.errorOut('CANCELLED');
    }

    // 带超时的分割调用
    const startedAt = Date.now();
    let result: subjectSegmentation.SegmentationResult;
    try {
      const visionInfo: subjectSegmentation.VisionInfo = { pixelMap: pixelMap };
      const config: subjectSegmentation.SegmentationConfig = {
        maxCount: maxCount,
        enableSubjectDetails: false,
        enableSubjectForegroundImage: true // 架构迁移：启用前景图用于双图渲染
      };
      result = await SubjectSegmentationService.withTimeout(
        this.adapter.doSegmentation(visionInfo, config),
        SEGMENTATION_TIMEOUT_MS
      );
    } catch (err) {
      const message = (err as Error).message ?? '';
      if (message === 'TIMEOUT') {
        return SubjectSegmentationService.errorOut('TIMEOUT');
      }
      if (message === 'CANCELLED') {
        return SubjectSegmentationService.errorOut('CANCELLED');
      }
      const bizErr = err as BusinessError;
      hilog.error(0x0000, TAG, 'doSegmentation failed: %{public}d %{public}s',
        bizErr.code ?? -1, bizErr.message ?? '');
      return SubjectSegmentationService.errorOut('SDK_ERROR');
    }
    const elapsed = Date.now() - startedAt;

    if (myGeneration !== this.sessionGeneration) {
      return SubjectSegmentationService.errorOut('CANCELLED');
    }

    // ── 解析 Core Vision 返回结构（本类内唯一允许的位置）──
    const full = result.fullSubject;
    if (full === undefined || full === null) {
      return SubjectSegmentationService.errorOut('SDK_ERROR');
    }
    const count = result.subjectCount ?? 0;
    const matting = full.mattingList;
    if (count <= 0 || matting === undefined || matting === null || matting.length === 0) {
      hilog.info(0x0000, TAG, 'no salient subject (%{public}d)', count);
      return SegmentOutcome.noSubject();
    }

    const weights = mattingListToWeights(matting);
    const rect = full.subjectRectangle;
    const bounds: RectData = rect !== undefined && rect !== null
      ? {
        left: rect.left,
        top: rect.top,
        width: rect.width,
        height: rect.height
      }
      : { left: 0, top: 0, width: 0, height: 0 };

    // RawMask 尺寸：以蒙版自身长度反推正方形不可行，Core Vision 约定
    // mattingList 与输入 PixelMap 同尺寸（w×h 行优先）
    const info = await pixelMap.getImageInfo();
    const maskW = info.size.width;
    const maskH = info.size.height;

    const validation = validateRawMask(maskW, maskH, weights, bounds);
    if (!validation.ok) {
      hilog.error(0x0000, TAG, 'raw mask invalid: %{public}s', validation.reason);
      return SubjectSegmentationService.errorOut('INVALID_MASK');
    }
    if (myGeneration !== this.sessionGeneration) {
      return SubjectSegmentationService.errorOut('CANCELLED');
    }

    hilog.info(0x0000, TAG,
      'segment ok in %{public}dms: subjects=%{public}d mask=%{public}dx%d',
      elapsed, count, maskW, maskH);

    // 提取前景图（透明背景，用于双图 colorFilter 渲染）
    const foregroundImage = full.foregroundImage;
    if (foregroundImage !== undefined && foregroundImage !== null) {
      hilog.info(0x0000, TAG, 'foreground image extracted');
    } else {
      hilog.warn(0x0000, TAG, 'foreground image not available');
    }

    const output: SegmentationOutput = {
      rawMask: { width: maskW, height: maskH, weights: weights },
      subjectCount: count,
      subjectBounds: bounds,
      foregroundImage: foregroundImage
    };
    return SegmentOutcome.ready(output);
  }

  /** 换图 / 页面离开：自增会话代次，使在途 segment 结果作废（V2 §30）。 */
  invalidate(): void {
    this.sessionGeneration++;
  }

  /** 释放 AI 服务资源。 */
  async release(): Promise<void> {
    this.invalidate();
    if (!this.initialized) {
      return;
    }
    try {
      await this.adapter.release();
    } catch (_err) {
      hilog.error(0x0000, TAG, 'release failed');
    }
    this.initialized = false;
    hilog.info(0x0000, TAG, 'subject segmentation released');
  }

  private static errorOut(code: SegErrorCode): SegmentOutcome {
    return SegmentOutcome.error(code);
  }

  /** Promise 超时竞速；超时抛 Error('TIMEOUT')。 */
  private static async withTimeout<T>(
    task: Promise<T>,
    timeoutMs: number
  ): Promise<T> {
    let timerId: number = -1;
    const timeout = new Promise<never>((_resolve, reject) => {
      timerId = setTimeout(() => {
        const t = new Error('TIMEOUT');
        reject(t);
      }, timeoutMs);
    });
    try {
      const winner = await Promise.race([task, timeout]);
      return winner as T;
    } finally {
      clearTimeout(timerId);
    }
  }
}

/** 模块级单例：全应用共享一次 AI 初始化。 */
let sharedInstance: SubjectSegmentationService | null = null;

export function getSubjectSegmentationService(): SubjectSegmentationService {
  if (sharedInstance === null || sharedInstance === undefined) {
    sharedInstance = new SubjectSegmentationService();
  }
  return sharedInstance;
}
