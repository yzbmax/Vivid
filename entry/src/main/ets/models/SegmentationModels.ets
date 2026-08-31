/**
 * AI 主体分割共享契约。
 *
 * 架构迁移（2026-08-26）：从 Worker 渲染管线迁移到双图 colorFilter 方案。
 * SegmentationOutput 新增 foregroundImage（透明背景前景图），用于 PreviewArea
 * 双图叠放渲染。rawMask 保留用于 Debug 视图，不再参与渲染。
 *
 * 注意：本文件现在 import @kit.ImageKit（为了 foregroundImage 类型），
 * 本地单元测试（src/test）无法直接加载——相关测试需迁移到 ohosTest 或删除。
 */

import { image } from '@kit.ImageKit';

/** 蒙版数据：width × height 的逐像素权重，0=背景 255=主体 1~254=概率/软边缘。 */
export interface MaskData {
  width: number;
  height: number;
  weights: Uint8Array;
}

/** 矩形区域（仅 Debug / 校验 / 日志用途）。 */
export interface RectData {
  left: number;
  top: number;
  width: number;
  height: number;
}

/**
 * SubjectSegmentationService 的统一输出（页面不得直接接触 Core Vision 返回结构）。
 *
 * foregroundImage：透明背景的前景图（主体已抠出），用于双图叠放渲染。
 * 调用方负责 release()，服务层不释放。
 */
export interface SegmentationOutput {
  rawMask: MaskData;
  subjectCount: number;
  subjectBounds: RectData;
  foregroundImage?: image.PixelMap;
}

/** 分割流程状态机（编辑页 UI 状态据此驱动）。 */
export type SegmentationStatus =
  'idle' | 'preparing' | 'segmenting' | 'processingMask' | 'ready' | 'error';

/**
 * 内部错误码（V2 §23：仅供日志/诊断区分；UI 只展示归并文案）。
 * NO_SUBJECT 不是 AI 异常——主体占比 <~0.5% 时 Core Vision 不识别（§24）。
 */
export type SegErrorCode =
  'INIT_FAILED'      // subjectSegmentation.init() 返回 false 或抛错
  | 'TIMEOUT'        // doSegmentation 超时
  | 'SDK_ERROR'      // SDK 运行异常
  | 'NO_SUBJECT'     // 未识别到明显主体
  | 'INVALID_MASK'   // RawMask 校验失败（长度/全零/尺寸/BBox 非法）
  | 'DECODE_FAILED'  // 图片解码失败
  | 'CANCELLED';     // 代次失效 / 用户离开

/** 蒙版置信度调优参数（V2 §11 预留，MaskProcessor 使用；V1 不进 UI）。 */
export interface MaskTuningConfig {
  lowConfidence: number;
  highConfidence: number;
}

// ───────────────────────── 常量 ─────────────────────────

/** Vivid 自定的 AI 工作图最长边上限（性能策略，非 SDK 限制，V2 §4）。 */
export const AI_WORK_MAX_EDGE: number = 1920;

/** 预览渲染最长边上限（V2 §37：滑块 P95≤100ms 达不到时优先下调此值）。 */
export const PREVIEW_MAX_EDGE: number = 1280;

/** 单次分割超时（毫秒），超时映射 TIMEOUT。 */
export const SEGMENTATION_TIMEOUT_MS: number = 20000;

/** 冻结的 Core Vision 配置 maxCount（V2 §6，允许范围 1~20）。 */
export const DEFAULT_MAX_SUBJECT_COUNT: number = 6;

/**
 * 错误码 → 用户可见文案。
 * 无主体 ≠ AI 服务异常，两者必须使用不同文案（V2 §24）。
 */
export function segErrorToMessage(code: SegErrorCode): string {
  if (code === 'NO_SUBJECT') {
    return '没有识别到明显主体';
  }
  if (code === 'CANCELLED') {
    return '';
  }
  if (code === 'TIMEOUT') {
    return '主体识别超时，请重试';
  }
  if (code === 'INVALID_MASK') {
    return '主体识别结果异常，请重试';
  }
  return '主体识别失败，请重试';
}

/**
 * 分割结果（ArkTS 不支持对象字面量联合类型，改用 class + 静态工厂）。
 * 字段按 status 取值：ready → output 非 undefined；error → code 非 undefined。
 *
 * 本类定义在 Kit-free 的 SegmentationModels 中，保证本地单测可加载。
 */
export class SegmentOutcome {
  status: 'ready' | 'noSubject' | 'error' = 'noSubject';
  output: SegmentationOutput | undefined = undefined;
  code: SegErrorCode | undefined = undefined;

  static ready(output: SegmentationOutput): SegmentOutcome {
    const o = new SegmentOutcome();
    o.status = 'ready';
    o.output = output;
    return o;
  }

  static noSubject(): SegmentOutcome {
    const o = new SegmentOutcome();
    o.status = 'noSubject';
    return o;
  }

  static error(code: SegErrorCode): SegmentOutcome {
    const o = new SegmentOutcome();
    o.status = 'error';
    o.code = code;
    return o;
  }
}
