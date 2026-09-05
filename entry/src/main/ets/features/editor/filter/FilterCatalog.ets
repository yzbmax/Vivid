import { FilterPreset } from './FilterModels';

/** Bundled LUT presets. Original is intentionally the first item. */
export const FILTER_PRESETS: FilterPreset[] = [
  {
    id: 'original',
    name: '原图',
    defaultStrength: 0,
    version: 1
  },
  {
    id: 'fieldnote',
    name: '纪实',
    lutPath: 'filters/Fieldnote.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'heartland',
    name: '原野',
    lutPath: 'filters/Heartland.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'meridian',
    name: '子午',
    lutPath: 'filters/Meridian.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'matinee',
    name: '午后',
    lutPath: 'filters/Matinee.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'postcard',
    name: '明信',
    lutPath: 'filters/Postcard.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'night_market',
    name: '夜市',
    lutPath: 'filters/NightMarket.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'dusk_tide',
    name: '暮潮',
    lutPath: 'filters/DuskTide.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'canopy',
    name: '林冠',
    lutPath: 'filters/Canopy.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'skylight',
    name: '天光',
    lutPath: 'filters/Skylight.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'lowsun',
    name: '斜阳',
    lutPath: 'filters/Lowsun.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'vel_cinematic_teal',
    name: '影青',
    lutPath: 'filters/VEL_Cinematic_Teal.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'vel_classic_teal_orange',
    name: '青橙',
    lutPath: 'filters/VEL_Classic_Teal_Orange.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'vel_film_fade',
    name: '褪色',
    lutPath: 'filters/VEL_Film_Fade.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'vel_golden_cinematic',
    name: '流金',
    lutPath: 'filters/VEL_Golden_Cinematic.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'vel_mono_contrast',
    name: '黑白',
    lutPath: 'filters/VEL_Mono_Contrast.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'vel_moody_blue',
    name: '幽蓝',
    lutPath: 'filters/VEL_Moody_Blue.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'vel_sunset_glow',
    name: '晚霞',
    lutPath: 'filters/VEL_Sunset_Glow.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'vel_vintage_chrome',
    name: '复古',
    lutPath: 'filters/VEL_Vintage_Chrome.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'vel_vivid_teal',
    name: '碧青',
    lutPath: 'filters/VEL_Vivid_Teal.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'vel_warm_film',
    name: '暖阳',
    lutPath: 'filters/VEL_Warm_Film.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'vel_warm_pastel',
    name: '暖柔',
    lutPath: 'filters/VEL_Warm_Pastel.cube',
    defaultStrength: 0.75,
    version: 1
  },
  {
    id: 'yt_moody_dark',
    name: '暗调',
    lutPath: 'filters/YT_Moody_Dark.cube',
    defaultStrength: 0.75,
    version: 1
  },
  // ──────── Vivid 0.1.9：8 款新增离线 LUT（实施计划 §2.1）────────
  {
    id: 'jade_mist',
    name: '玉烟',
    lutPath: 'filters/JadeMist.cube',
    defaultStrength: 0.68,
    version: 1
  },
  {
    id: 'cinnabar_glow',
    name: '丹霞',
    lutPath: 'filters/CinnabarGlow.cube',
    defaultStrength: 0.65,
    version: 1
  },
  {
    id: 'ink_noir',
    name: '墨影',
    lutPath: 'filters/InkNoir.cube',
    defaultStrength: 0.80,
    version: 1
  },
  {
    id: 'rice_paper',
    name: '宣纸',
    lutPath: 'filters/RicePaper.cube',
    defaultStrength: 0.62,
    version: 1
  },
  {
    id: 'tea_film',
    name: '茶褐',
    lutPath: 'filters/TeaFilm.cube',
    defaultStrength: 0.72,
    version: 1
  },
  {
    id: 'celadon_cool',
    name: '青瓷',
    lutPath: 'filters/CeladonCool.cube',
    defaultStrength: 0.70,
    version: 1
  },
  {
    id: 'amber_hour',
    name: '琥珀',
    lutPath: 'filters/AmberHour.cube',
    defaultStrength: 0.66,
    version: 1
  },
  {
    id: 'moonlit_blue',
    name: '月青',
    lutPath: 'filters/MoonlitBlue.cube',
    defaultStrength: 0.74,
    version: 1
  }
];
