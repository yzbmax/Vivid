/** 文字图层字体目录。所有字体选择都经过此目录解析，保证回退顺序稳定。 */

export interface FontCatalogEntry {
  fontKey: string;
  label: string;
  family: string;
  rawfilePath: string;
  fallbackKeys: string[];
}

export const FONT_CATALOG: FontCatalogEntry[] = [
  {
    fontKey: 'system_sans',
    label: '鸿蒙黑体',
    family: 'HarmonyOS Sans SC',
    rawfilePath: '',
    fallbackKeys: ['system_sans']
  },
  {
    fontKey: 'noto_serif_sc',
    label: '思源宋体',
    family: 'Noto Serif SC',
    rawfilePath: 'fonts/notoserifsc.ttf',
    fallbackKeys: ['noto_serif_sc', 'system_sans']
  },
  {
    fontKey: 'gkai',
    label: '古籍楷体',
    family: 'G Kai',
    rawfilePath: 'fonts/gkai.ttf',
    fallbackKeys: ['gkai', 'noto_serif_sc', 'system_sans']
  },
  {
    fontKey: 'system_mono',
    label: '等宽题签',
    family: 'HarmonyOS Sans Mono',
    rawfilePath: '',
    fallbackKeys: ['system_mono', 'system_sans']
  },
  {
    fontKey: 'noto_serif_latin',
    label: '西文衬线',
    family: 'Noto Serif',
    rawfilePath: 'fonts/notoserif.ttf',
    fallbackKeys: ['noto_serif_latin', 'noto_serif_sc', 'system_sans']
  }
];

/** 固定 8 色文字色板（ARGB）。 */
export const TEXT_COLOR_PALETTE: number[] = [
  0xFF241918,
  0xFFF2F1ED,
  0xFFB23B2F,
  0xFF7B171B,
  0xFF004645,
  0xFFB7791F,
  0xFF574140,
  0xFFFFF8F7
];

/** 兼容更明确的目录命名。 */
export const TEXT_COLORS: number[] = TEXT_COLOR_PALETTE;

export function findFontEntry(fontKey: string): FontCatalogEntry | null {
  for (let i = 0; i < FONT_CATALOG.length; i++) {
    if (FONT_CATALOG[i].fontKey === fontKey) {
      return FONT_CATALOG[i];
    }
  }
  return null;
}

export function isFontKey(fontKey: string): boolean {
  return findFontEntry(fontKey) !== null;
}

/** 按目录跳过注册失败的字体；不改变快照中保存的用户选择。 */
export function resolveFontKey(fontKey: string, unavailableKeys: string[] = []): string {
  const chain = fontFallbackChain(fontKey);
  for (let i = 0; i < chain.length; i++) {
    if (unavailableKeys.indexOf(chain[i]) < 0) {
      return chain[i];
    }
  }
  return 'system_sans';
}

/** 返回指定字体的完整、确定性回退链。 */
export function fontFallbackChain(fontKey: string): string[] {
  const entry = findFontEntry(fontKey);
  if (entry === null) {
    return ['system_sans'];
  }
  return entry.fallbackKeys.slice();
}

/** 未知颜色回退墨黑，避免快照中的任意值绕过固定色板。 */
export function resolveTextColor(colorArgb: number): number {
  for (let i = 0; i < TEXT_COLOR_PALETTE.length; i++) {
    if (TEXT_COLOR_PALETTE[i] === colorArgb) {
      return colorArgb;
    }
  }
  return TEXT_COLOR_PALETTE[0];
}
