import { TraditionalColorItem } from './ColophonModels';

/**
 * 中国传统色谱名录（40 种经典国风雅色）
 */
export const TRADITIONAL_COLORS: TraditionalColorItem[] = [
  { name: '缃色', hex: '#E5D3B3', r: 229, g: 211, b: 179, pinyin: 'xiāng sè' },
  { name: '苍绿', hex: '#3F5D4D', r: 63, g: 93, b: 77, pinyin: 'cāng lǜ' },
  { name: '黄栌', hex: '#E29D45', r: 226, g: 157, b: 69, pinyin: 'huáng lú' },
  { name: '金盏', hex: '#F0B639', r: 240, g: 182, b: 57, pinyin: 'jīn zhǎn' },
  { name: '松烟', hex: '#2F353B', r: 47, g: 53, b: 59, pinyin: 'sōng yān' },
  { name: '螺子黛', hex: '#2B333E', r: 43, g: 51, b: 62, pinyin: 'luó zǐ dài' },
  { name: '朱砂', hex: '#B23B2F', r: 178, g: 59, b: 47, pinyin: 'zhū shā' },
  { name: '月白', hex: '#D4E5EF', r: 212, g: 229, b: 239, pinyin: 'yuè bái' },
  { name: '天青', hex: '#86A697', r: 134, g: 166, b: 151, pinyin: 'tiān qīng' },
  { name: '鸦青', hex: '#293047', r: 41, g: 48, b: 71, pinyin: 'yā qīng' },
  { name: '秋香', hex: '#D5B158', r: 213, g: 177, b: 88, pinyin: 'qiū xiāng' },
  { name: '琥珀', hex: '#CA6924', r: 202, g: 105, b: 36, pinyin: 'hǔ pò' },
  { name: '黛绿', hex: '#28483B', r: 40, g: 72, b: 59, pinyin: 'dài lǜ' },
  { name: '柘黄', hex: '#C67915', r: 198, g: 121, b: 21, pinyin: 'zhè huáng' },
  { name: '暮云灰', hex: '#6C7B89', r: 108, g: 123, b: 137, pinyin: 'mù yún huī' },
  { name: '脂红', hex: '#C83C23', r: 200, g: 60, b: 35, pinyin: 'zhī hóng' },
  { name: '檀色', hex: '#B26D5D', r: 178, g: 109, b: 93, pinyin: 'tán sè' },
  { name: '藕荷', hex: '#BC987E', r: 188, g: 152, b: 126, pinyin: 'ǒu hé' },
  { name: '水红', hex: '#E38C7A', r: 227, g: 140, b: 122, pinyin: 'shuǐ hóng' },
  { name: '竹青', hex: '#5B7E58', r: 91, g: 126, b: 88, pinyin: 'zhú qīng' },
  { name: '雄黄', hex: '#E8853B', r: 232, g: 133, b: 59, pinyin: 'xióng huáng' },
  { name: '碧玉', hex: '#50786F', r: 80, g: 120, b: 111, pinyin: 'bì yù' },
  { name: '翡翠', hex: '#3E855B', r: 62, g: 133, b: 91, pinyin: 'fěi cuì' },
  { name: '姜黄', hex: '#DFAF44', r: 223, g: 175, b: 68, pinyin: 'jiāng huáng' },
  { name: '胭脂', hex: '#9D2933', r: 157, g: 41, b: 51, pinyin: 'yān zhi' },
  { name: '东方既白', hex: '#9FB5C4', r: 159, g: 181, b: 196, pinyin: 'dōng fāng jì bái' },
  { name: '霜色', hex: '#E8ECF1', r: 232, g: 236, b: 241, pinyin: 'shuāng sè' },
  { name: '靛蓝', hex: '#1B315E', r: 27, g: 49, b: 94, pinyin: 'diàn lán' },
  { name: '焦墨', hex: '#1C1C1C', r: 28, g: 28, b: 28, pinyin: 'jiāo mò' },
  { name: '铅白', hex: '#F0F0F4', r: 240, g: 240, b: 244, pinyin: 'qiān bái' },
  { name: '杏黄', hex: '#F29A38', r: 242, g: 154, b: 56, pinyin: 'xìng huáng' },
  { name: '琉璃黄', hex: '#E3A824', r: 227, g: 168, b: 36, pinyin: 'liú lí huáng' },
  { name: '苍苔', hex: '#566847', r: 86, g: 104, b: 71, pinyin: 'cāng tái' },
  { name: '荼白', hex: '#F3F9F1', r: 243, g: 249, b: 241, pinyin: 'tú bái' },
  { name: '藕丝秋半', hex: '#C4A8A3', r: 196, g: 168, b: 163, pinyin: 'ǒu sī qiū bàn' },
  { name: '暮山紫', hex: '#796878', r: 121, g: 104, b: 120, pinyin: 'mù shān zǐ' },
  { name: '远山黛', hex: '#4C5958', r: 76, g: 89, b: 88, pinyin: 'yuǎn shān dài' },
  { name: '赤金', hex: '#F2BE45', r: 242, g: 190, b: 69, pinyin: 'chì jīn' },
  { name: '豆绿', hex: '#9BB496', r: 155, g: 180, b: 150, pinyin: 'dòu lǜ' },
  { name: '霁蓝', hex: '#2F4F75', r: 47, g: 79, b: 117, pinyin: 'jì lán' }
];

/**
 * 加权欧氏色彩感知距离
 */
function colorDistance(r1: number, g1: number, b1: number, r2: number, g2: number, b2: number): number {
  const dr = r1 - r2;
  const dg = g1 - g2;
  const db = b1 - b2;
  return Math.sqrt(2 * dr * dr + 4 * dg * dg + 3 * db * db);
}

/**
 * 根据输入的 RGB 查找最接近的中国传统色
 */
export function findClosestTraditionalColor(r: number, g: number, b: number): TraditionalColorItem {
  let minDistance = Number.MAX_VALUE;
  let bestMatch: TraditionalColorItem = TRADITIONAL_COLORS[0];

  for (let i = 0; i < TRADITIONAL_COLORS.length; i++) {
    const item = TRADITIONAL_COLORS[i];
    const dist = colorDistance(r, g, b, item.r, item.g, item.b);
    if (dist < minDistance) {
      minDistance = dist;
      bestMatch = item;
    }
  }

  return {
    name: bestMatch.name,
    hex: bestMatch.hex,
    r: bestMatch.r,
    g: bestMatch.g,
    b: bestMatch.b,
    pinyin: bestMatch.pinyin
  };
}
