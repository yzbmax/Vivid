import { WorkRecord, WorkStatus } from './WorkRecord';

/**
 * 卷宗案牍统计模型（ArchiveStats）
 * 用于「我的」页面本地创作数据看板，100% 端侧计算，零云端依赖。
 */
export interface ArchiveStats {
  /** 总归档卷宗数 */
  totalCount: number;
  /** 中文传统大写数字（如：拾贰） */
  totalCountChinese: string;
  /** 已封缄（已完成装裱保存）卷数 */
  sealedCount: number;
  /** 研墨草稿数 */
  draftCount: number;
  /** 今日创作录入数 */
  todayCount: number;
  /** 主导直方图影调（如：阴阳错落 / 极目高明） */
  dominantTone: string;
  /** 主导影调雅致文人评语（如：明晦相生 · 虚实合度） */
  dominantTonePoetic: string;
  /** 色温风骨偏好（如：日暮微曛 / 雪岭霜晨 / 素宣中正） */
  temperatureBias: string;
  /** 色温数值与倾向详情说明（如：均温 +12 · 偏暖） */
  temperatureDetail: string;
  /** 案牍结语古风总评 */
  poeticSummary: string;
}

const CHINESE_DIGITS: string[] = ['零', '壹', '贰', '叁', '肆', '伍', '陆', '柒', '捌', '玖'];

/**
 * 将整数转换为大写中文数字（0 ~ 99），超过 99 返回常规字符串
 */
export function numberToChineseNumeral(num: number): string {
  if (num <= 0) {
    return '零';
  }
  if (num < 10) {
    return CHINESE_DIGITS[num];
  }
  if (num === 10) {
    return '拾';
  }
  if (num < 20) {
    return '拾' + CHINESE_DIGITS[num % 10];
  }
  if (num < 100) {
    const tens = Math.floor(num / 10);
    const ones = num % 10;
    if (ones === 0) {
      return CHINESE_DIGITS[tens] + '拾';
    }
    return CHINESE_DIGITS[tens] + '拾' + CHINESE_DIGITS[ones];
  }
  if (num === 100) {
    return '壹百';
  }
  return num.toString();
}

/**
 * 影调雅称映射（纯函数映射，避免动态索引）
 */
export function getTonePoetic(tone: string): string {
  if (tone === '阴阳错落') {
    return '明晦相生 · 虚实合度';
  }
  if (tone === '极目高明') {
    return '素宣澄澈 · 清气满纸';
  }
  if (tone === '玄冥幽微') {
    return '墨气沉凝 · 幽深内敛';
  }
  if (tone === '温润柔和') {
    return '淡雅从容 · 秀润天成';
  }
  if (tone === '山河待绘') {
    return '虚席以待 · 待启首卷';
  }
  return '五色兼备 · 气象万千';
}

/**
 * 根据本地全部作品列表计算案牍数据
 */
export function computeArchiveStats(works: WorkRecord[]): ArchiveStats {
  if (!works || works.length === 0) {
    return {
      totalCount: 0,
      totalCountChinese: '零',
      sealedCount: 0,
      draftCount: 0,
      todayCount: 0,
      dominantTone: '山河待绘',
      dominantTonePoetic: '虚席以待 · 待启首卷',
      temperatureBias: '素宣中正',
      temperatureDetail: '素宣待染',
      poeticSummary: '长卷未染，素宣待启。轻移案前朱砚，以光影为笔，点染山川草木。'
    };
  }

  const totalCount: number = works.length;
  const totalCountChinese: string = numberToChineseNumeral(totalCount);

  let sealedCount: number = 0;
  let draftCount: number = 0;
  let todayCount: number = 0;
  let tempSum: number = 0;

  const now = new Date();
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();

  // 显式统计各调性频次，杜绝动态索引与 Object.keys
  let countDappled: number = 0; // 阴阳错落
  let countHigh: number = 0;    // 极目高明
  let countLow: number = 0;     // 玄冥幽微
  let countSoft: number = 0;    // 温润柔和
  let countRich: number = 0;    // 浑厚华滋

  for (let i = 0; i < works.length; i++) {
    const w = works[i];
    if (w.status === WorkStatus.Sealed) {
      sealedCount++;
    } else {
      draftCount++;
    }

    if (w.createdAt >= todayStart) {
      todayCount++;
    }

    // 色温累加
    if (w.adjustments && typeof w.adjustments.temperature === 'number') {
      tempSum += w.adjustments.temperature;
    }

    // 影调统计
    const label = (w.toneLabel && w.toneLabel.length > 0) ? w.toneLabel : '浑厚华滋';
    if (label === '阴阳错落') {
      countDappled++;
    } else if (label === '极目高明') {
      countHigh++;
    } else if (label === '玄冥幽微') {
      countLow++;
    } else if (label === '温润柔和') {
      countSoft++;
    } else {
      countRich++;
    }
  }

  // 找出出现最多的影调
  let dominantTone = '浑厚华滋';
  let maxCount = countRich;

  if (countDappled > maxCount) {
    maxCount = countDappled;
    dominantTone = '阴阳错落';
  }
  if (countHigh > maxCount) {
    maxCount = countHigh;
    dominantTone = '极目高明';
  }
  if (countLow > maxCount) {
    maxCount = countLow;
    dominantTone = '玄冥幽微';
  }
  if (countSoft > maxCount) {
    maxCount = countSoft;
    dominantTone = '温润柔和';
  }

  const dominantTonePoetic = getTonePoetic(dominantTone);

  // 计算平均色温与风骨
  const avgTemp = Math.round(tempSum / totalCount);
  let temperatureBias = '素宣中正';
  let temperatureDetail = '中正调 · 均值 ' + (avgTemp >= 0 ? '+' : '') + avgTemp.toString();
  if (avgTemp > 8) {
    temperatureBias = '日暮微曛';
    temperatureDetail = '偏暖调 · 均值 +' + avgTemp.toString();
  } else if (avgTemp < -8) {
    temperatureBias = '雪岭霜晨';
    temperatureDetail = '偏冷调 · 均值 ' + avgTemp.toString();
  }

  // 生成总评文案
  let poeticSummary = '';
  if (totalCount < 3) {
    poeticSummary = '初试锋芒，笔意清新。卷宗已有雏形，待墨气渐浓，自有大家气象。';
  } else if (totalCount < 8) {
    poeticSummary = '藏卷初成，意趣渐生。诸卷明暗相宜，已有文人案头丹青妙韵。';
  } else {
    poeticSummary = '藏卷渐丰，风骨自立。览观诸卷，光影如流泉出谷，已具文人法度。';
  }

  return {
    totalCount,
    totalCountChinese,
    sealedCount,
    draftCount,
    todayCount,
    dominantTone,
    dominantTonePoetic,
    temperatureBias,
    temperatureDetail,
    poeticSummary
  };
}
