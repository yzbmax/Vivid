import { AdjustParams } from './EditModels';
import { ToneMetrics, AuditDiagnosis } from './ImageToneModels';
import { WatermarkConfig } from './SharedContracts';

/**
 * 作品描述（案卷批注）生成上下文
 */
export interface DescriptionContext {
  adjustments?: AdjustParams;
  width?: number;
  height?: number;
  exif?: Partial<WatermarkConfig>;
  toneMetrics?: ToneMetrics;
  audit?: AuditDiagnosis;
}

/** 曝光/亮度 → 光影描述 */
function describeLightness(exposure: number, brightness: number): string {
  const combined = exposure * 0.6 + brightness * 0.4;
  if (combined > 30) {
    return '光影明快，通篇透亮';
  } else if (combined > 10) {
    return '光影柔和，层次分明';
  } else if (combined > -10) {
    return '光影均衡，不偏不倚';
  } else if (combined > -30) {
    return '明暗含蓄，氛围沉郁';
  } else {
    return '暗调浓厚，深沉厚重';
  }
}

/** 对比度 → 反差描述 */
function describeContrast(contrast: number): string {
  if (contrast > 30) {
    return '反差强烈，棱角分明';
  } else if (contrast > 10) {
    return '对比适度，层次清晰';
  } else if (contrast > -10) {
    return '反差平和，过渡均匀';
  } else if (contrast > -30) {
    return '层次柔和，边界模糊';
  } else {
    return '色调绵软，浑然一体';
  }
}

/** 饱和度 → 色彩描述 */
function describeSaturation(saturation: number): string {
  if (saturation > 30) {
    return '色彩浓郁，鲜艳夺目';
  } else if (saturation > 10) {
    return '色泽饱满，富有生气';
  } else if (saturation > -10) {
    return '色彩自然，不事雕琢';
  } else if (saturation > -30) {
    return '素雅清淡，意趣幽远';
  } else {
    return '近于水墨，素净空灵';
  }
}

/** 宽高比 → 构图描述 */
export function describeComposition(width: number, height: number): string {
  if (width <= 0 || height <= 0) {
    return '';
  }
  const ratio = width / height;
  if (ratio > 1.6) {
    return '长卷形制，气势开阔';
  } else if (ratio > 1.2) {
    return '横幅构图，视野舒展';
  } else if (ratio > 0.85) {
    return '方帧端正，稳重大方';
  } else if (ratio > 0.6) {
    return '竖幅构图，适宜细观';
  } else {
    return '窄长竖帧，别具一格';
  }
}

/**
 * 将 EXIF 拍摄时间转化为古风岁时物候与天时日光描述
 *
 * @param timeText 格式形如 "2025.11.29 16:18" 或 "2025:11:29 16:18:00"
 */
export function describeSolarTermAndTime(timeText?: string): string {
  if (!timeText || timeText.trim().length === 0) {
    return '';
  }
  const clean = timeText.trim();
  const parts = clean.split(' ');
  let month = 0;
  let day = 0;
  let hour = -1;

  if (parts.length >= 1) {
    const dateParts = parts[0].split(/[.:\-/]/);
    if (dateParts.length >= 3) {
      month = parseInt(dateParts[1], 10) || 0;
      day = parseInt(dateParts[2], 10) || 0;
    }
  }
  if (parts.length >= 2) {
    const timeParts = parts[1].split(':');
    if (timeParts.length >= 1) {
      hour = parseInt(timeParts[0], 10);
    }
  }

  let seasonPart = '';
  if (month === 1 || month === 2) {
    seasonPart = '岁次隆冬';
  } else if (month === 3 || month === 4) {
    seasonPart = '岁在芳春';
  } else if (month === 5 || month === 6) {
    seasonPart = '时值首夏';
  } else if (month === 7 || month === 8) {
    seasonPart = '炎夏流火';
  } else if (month === 9 || month === 10) {
    seasonPart = '金秋爽朗';
  } else if (month === 11) {
    seasonPart = day >= 15 ? '岁次初冬' : '暮秋初冬';
  } else if (month === 12) {
    seasonPart = '岁末冬月';
  }

  let timeOfDayPart = '';
  if (hour >= 5 && hour < 8) {
    timeOfDayPart = '晨光熹微';
  } else if (hour >= 8 && hour < 11) {
    timeOfDayPart = '朝阳融融';
  } else if (hour >= 11 && hour < 14) {
    timeOfDayPart = '正午日丽';
  } else if (hour >= 14 && hour < 16) {
    timeOfDayPart = '晴日初煦';
  } else if (hour >= 16 && hour < 18) {
    timeOfDayPart = '申末晚晴，斜阳穿林';
  } else if (hour >= 18 && hour < 20) {
    timeOfDayPart = '日落熔金';
  } else if (hour >= 20 || (hour >= 0 && hour < 5)) {
    timeOfDayPart = '沉夜幽致';
  }

  if (seasonPart.length > 0 && timeOfDayPart.length > 0) {
    return `${seasonPart}${timeOfDayPart}`;
  } else if (seasonPart.length > 0) {
    return seasonPart;
  } else if (timeOfDayPart.length > 0) {
    return timeOfDayPart;
  }
  return '';
}

/**
 * 将镜头机型与拍摄参数转化为光学画理描述
 *
 * @param deviceModel 机型
 * @param paramsText 参数文本（如 "50mm  f/1.8  1/500s  ISO320"）
 */
export function describeLensAndOptics(deviceModel?: string, paramsText?: string): string {
  if (!paramsText || paramsText.trim().length === 0) {
    return '';
  }
  const text = paramsText.toLowerCase();
  const parts: string[] = [];

  // 1. 焦距
  if (text.includes('50mm') || text.includes('45mm') || text.includes('55mm')) {
    parts.push('以五旬标头取景');
  } else if (text.includes('24mm') || text.includes('28mm') || text.includes('16mm') || text.includes('35mm')) {
    parts.push('广角开阔舒展');
  } else if (text.includes('85mm') || text.includes('135mm') || text.includes('200mm')) {
    parts.push('远望凝神，裁取方寸');
  }

  // 2. 光圈
  const fMatch = text.match(/f\/(\d+(?:\.\d+)?)/);
  if (fMatch) {
    const fVal = parseFloat(fMatch[1]);
    if (fVal <= 2.0) {
      parts.push('大光圈虚实相生');
    } else if (fVal >= 8.0) {
      parts.push('景深深邃，巨细靡遗');
    }
  }

  // 3. 快门
  if (text.includes('1/500s') || text.includes('1/1000s') || text.includes('1/2000s') || text.includes('1/4000s')) {
    parts.push('疾光定格刹那');
  } else if (text.match(/(?:[1-9]\d*s|0\.[3-9]s)/)) {
    parts.push('慢门流光');
  }

  return parts.join('，');
}

/**
 * 将直方图明暗调性转化为古风光影评语
 */
export function describeToneAndLight(metrics?: ToneMetrics): string {
  if (!metrics) {
    return '光影均衡，不偏不倚';
  }
  switch (metrics.toneCategory) {
    case 'dappled_contrast':
      return '直方呈阴阳错落之势：浓荫深沉如渊，碎金耀然跃动，光隙错落有致';
    case 'high_key':
      return '直方极目高明：全幅空灵通透，高光充盈而神韵清澈，不染纤尘';
    case 'low_key':
      return '直方玄冥深致：玄墨厚重，微光潜沉含蓄，韵味在幽深处悠然而生';
    case 'soft_subtle':
      return '直方烟云冲和：明暗过渡绵密，色调温润如玉，气象冲和';
    case 'rich_full':
      return '直方气脉丰匀：黑白灰九品层次井然，由明入晦气脉贯通';
    case 'balanced':
    default:
      return '光影均衡，不偏不倚，反差平和，过渡均匀';
  }
}

/**
 * 格式化官署校勘修改建议
 */
export function generateAuditSuggestion(audit?: AuditDiagnosis): string {
  if (!audit || !audit.hasIssue) {
    return '';
  }
  return `【${audit.title}】${audit.description} ${audit.recommendation}`;
}

/**
 * 生成作品描述（重载方法）
 */
export function generateWorkDescription(
  contextOrAdjustments: DescriptionContext | AdjustParams,
  width?: number,
  height?: number
): string {
  const ctx = contextOrAdjustments as DescriptionContext;
  const adj = contextOrAdjustments as AdjustParams;

  // 严格遵循 ArkTS 规范：通过接口已知字段安全判定是否为 DescriptionContext
  const isContext = ctx.toneMetrics !== undefined ||
    ctx.exif !== undefined ||
    ctx.audit !== undefined ||
    ctx.adjustments !== undefined;

  if (!isContext) {
    // 老版调用签名降级兼容
    const w = width ?? 0;
    const h = height ?? 0;
    const parts: string[] = [];
    parts.push(describeLightness(adj.exposure, adj.brightness));
    parts.push(describeContrast(adj.contrast));
    parts.push(describeSaturation(adj.saturation));
    const composition = describeComposition(w, h);
    if (composition.length > 0) {
      parts.push(composition);
    }
    let result = '此帧' + parts[0] + '，' + parts[1] + '，' + parts[2] + '。';
    if (parts.length > 3) {
      result += parts[3] + '。';
    }
    return result;
  }

  // 新版多要素融合生成
  const sentences: string[] = [];

  // 1. 岁时与天时
  const timeDesc = describeSolarTermAndTime(ctx.exif?.timeText);
  // 2. 光学与名器
  const opticsDesc = describeLensAndOptics(ctx.exif?.deviceModel, ctx.exif?.paramsText);

  if (timeDesc.length > 0 && opticsDesc.length > 0) {
    sentences.push(`${timeDesc}，${opticsDesc}。`);
  } else if (timeDesc.length > 0) {
    sentences.push(`${timeDesc}。`);
  } else if (opticsDesc.length > 0) {
    sentences.push(`${opticsDesc}。`);
  }

  // 3. 直方图明暗品格
  const toneDesc = describeToneAndLight(ctx.toneMetrics);
  sentences.push(`${toneDesc}。`);

  // 4. 构图形制
  const w = ctx.width ?? 0;
  const h = ctx.height ?? 0;
  const comp = describeComposition(w, h);
  if (comp.length > 0) {
    sentences.push(`${comp}。`);
  }

  return sentences.join('');
}
