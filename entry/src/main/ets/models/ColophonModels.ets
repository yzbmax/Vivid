/**
 * 案卷考评鉴藏印章类型
 */
export enum AppraisalSealType {
  SHEN_PIN = 'shen_pin',
  YI_PIN = 'yi_pin',
  MIAO_PIN = 'miao_pin',
  YUE = 'yue',
  JIA_SHANG = 'jia_shang'
}

/**
 * 印章元数据
 */
export interface AppraisalSealMeta {
  type: AppraisalSealType;
  label: string;
  glyph: string;
  description: string;
}

/**
 * 预设鉴藏印章列表
 */
export const APPRAISAL_SEALS: AppraisalSealMeta[] = [
  { type: AppraisalSealType.SHEN_PIN, label: '神品', glyph: '神', description: '妙造自然，格高气华' },
  { type: AppraisalSealType.YI_PIN, label: '逸品', glyph: '逸', description: '绝俗脱略，意趣高迈' },
  { type: AppraisalSealType.MIAO_PIN, label: '妙品', glyph: '妙', description: '生动逼真，神采飞扬' },
  { type: AppraisalSealType.YUE, label: '已阅', glyph: '阅', description: '案卷封缄，钦准存档' },
  { type: AppraisalSealType.JIA_SHANG, label: '甲上', glyph: '甲', description: '格物严谨，品第卓绝' }
];

/**
 * 中国传统色谱项
 */
export interface TraditionalColorItem {
  name: string;
  hex: string;
  r: number;
  g: number;
  b: number;
  pinyin?: string;
}

/**
 * 题跋长卷装裱配置
 */
export interface ColophonConfig {
  workTitle: string;
  fileNo: string;
  dateText: string;
  notesText: string;
  sealType: AppraisalSealType;
  showColorPalette: boolean;
  palette: TraditionalColorItem[];
  authorSignature?: string;
}

/**
 * 默认长卷配置
 */
export function createDefaultColophonConfig(
  workTitle: string = '午后习作',
  fileNo: string = 'VIVID-001',
  notesText: string = '此帧光影柔和，层次分明，反差平和，过渡均匀，色彩自然，不事雕琢。'
): ColophonConfig {
  return {
    workTitle,
    fileNo,
    dateText: '2026.09.07',
    notesText,
    sealType: AppraisalSealType.YUE,
    showColorPalette: true,
    palette: []
  };
}
