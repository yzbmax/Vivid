/**
 * 直方图明暗调性与官署校勘模型定义
 */

/**
 * 直方图明暗调性分类
 */
export type ToneCategory =
  | 'dappled_contrast' // 阴阳错落 / 斑驳大光比（双峰分布，如阳光穿透林荫）
  | 'high_key'         // 极目高明 / 高调通透（偏右，明亮通透）
  | 'low_key'          // 玄冥深致 / 暗调幽沉（偏左，深邃沉厚）
  | 'soft_subtle'      // 烟云冲和 / 柔调平正（居中集中，反差较小）
  | 'rich_full'        // 气脉丰匀 / 全阶调饱满（跨度均衡，层次丰富）
  | 'balanced';        // 平和中正 / 常规均衡

/**
 * 直方图统计指标
 */
export interface ToneMetrics {
  meanBrightness: number;     // 平均亮度 0..255
  stdDev: number;             // 亮度离散标准差（反差指标）
  shadowRatio: number;        // 暗部占比 (Y < 40) 0..1
  highlightRatio: number;     // 高光占比 (Y > 215) 0..1
  isBimodal: boolean;         // 是否呈现双峰分布（强明暗两极对立）
  toneCategory: ToneCategory; // 调性分类
  toneLabel: string;          // 古风调性标签（如“阴阳错落”）
}

/**
 * 官署校勘极端曝光诊断类型
 */
export type AuditIssueType =
  | 'none'
  | 'highlight_clipping'      // 高光溢出死白
  | 'shadow_clipping'         // 暗部死黑发堵
  | 'harsh_contrast'          // 反差过硬生切
  | 'low_contrast';           // 灰雾发蒙反差弱

/**
 * 官署校勘极端曝光诊断详情
 */
export interface AuditDiagnosis {
  hasIssue: boolean;
  issueType: AuditIssueType;
  title: string;              // 如 "官署校勘"
  description: string;        // 现象描述
  recommendation: string;     // 针对性操作建议
  targetParam: string;        // 调整目标参数：'exposure' | 'brightness' | 'contrast'
  suggestedDelta: number;     // 推荐增减数值（如 -15, +20）
}

/**
 * 创建默认均衡调性指标
 */
export function createDefaultToneMetrics(): ToneMetrics {
  return {
    meanBrightness: 128,
    stdDev: 40,
    shadowRatio: 0.1,
    highlightRatio: 0.1,
    isBimodal: false,
    toneCategory: 'balanced',
    toneLabel: '平和中正'
  };
}

/**
 * 创建默认无异常校勘
 */
export function createDefaultAuditDiagnosis(): AuditDiagnosis {
  return {
    hasIssue: false,
    issueType: 'none',
    title: '官署校勘',
    description: '通篇阴阳适度，九品阶调井然。',
    recommendation: '光影得宜，无需另作修撰。',
    targetParam: '',
    suggestedDelta: 0
  };
}
