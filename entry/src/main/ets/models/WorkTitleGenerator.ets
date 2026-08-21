/**
 * 作品标题自动生成器（时间序列式）。
 *
 * 根据创建时间 + 当日作品序号生成古风标题。
 * 格式："{时段}习作 · 第N卷"
 * 示例："午后习作 · 第三卷"
 */

/** 时段划分 */
function getTimePeriod(hour: number): string {
  if (hour >= 5 && hour <= 11) {
    return '晨间';
  } else if (hour >= 12 && hour <= 17) {
    return '午后';
  } else if (hour >= 18 && hour <= 21) {
    return '暮色';
  } else {
    return '深夜';
  }
}

/** 序号转中文数字 */
function toChineseNumeral(n: number): string {
  const digits = ['〇', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
  if (n <= 0) {
    return '〇';
  }
  if (n < 10) {
    return digits[n];
  }
  if (n < 20) {
    return n === 10 ? '十' : '十' + digits[n - 10];
  }
  if (n < 100) {
    const tens = Math.floor(n / 10);
    const ones = n % 10;
    const tensStr = tens === 1 ? '十' : digits[tens] + '十';
    return ones === 0 ? tensStr : tensStr + digits[ones];
  }
  return n.toString();
}

/**
 * 生成作品标题。
 *
 * @param createdAt 创建时间戳（毫秒）
 * @param todayCount 当日已有作品数（不含当前新作品）
 * @returns 自动生成的标题字符串
 */
export function generateWorkTitle(createdAt: number, todayCount: number): string {
  const d = new Date(createdAt);
  const hour = d.getHours();
  const period = getTimePeriod(hour);
  const seq = toChineseNumeral(todayCount + 1);

  return period + '习作 · 第' + seq + '卷';
}
