import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { LengthMetricsUnit } from '@kit.ArkUI';

/** 官方各品牌透明 PNG 精确高宽比 (width / height) */
export const LOGO_ASPECT_RATIOS: Record<string, number> = {
  'apple': 480 / 590,         // 0.81
  'canon': 480 / 100,         // 4.80
  'casio': 480 / 91,          // 5.27
  'dji': 480 / 277,           // 1.73
  'fujifilm': 480 / 80,       // 6.00
  'gopro': 480 / 147,         // 3.26
  'hasselblad': 480 / 45,     // 10.66
  'honor': 480 / 92,          // 5.21
  'huawei': 480 / 488,        // 0.98
  'insta360': 480 / 145,      // 3.31
  'kodak': 480 / 434,         // 1.10
  'konica_minolta': 480 / 279,// 1.72
  'leica': 480 / 480,         // 1.00
  'lumix': 480 / 109,         // 4.40
  'mamiya': 480 / 146,        // 3.28
  'master': 480 / 480,        // 1.00
  'nikon': 480 / 480,         // 1.00
  'olympus': 480 / 90,        // 5.33
  'oppo': 480 / 114,          // 4.21
  'panasonic': 480 / 77,      // 6.23
  'pentax': 480 / 97,         // 4.94
  'phase_one': 480 / 66,      // 7.27
  'polaroid': 480 / 95,       // 5.05
  'ricoh': 480 / 87,          // 5.51
  'rollei': 480 / 132,        // 3.63
  'samsung': 480 / 159,       // 3.01
  'sigma': 480 / 90,          // 5.33
  'sony': 480 / 84,           // 5.71
  'tamron': 480 / 108,        // 4.44
  'vivo': 480 / 126,          // 3.80
  'xiaomi': 480 / 128,        // 3.75
  'xmage': 480 / 180,         // 2.66
  'zeiss': 480 / 480          // 1.00
};

/** 获取官方正版品牌 PNG 的 media Resource 句柄 */
export function getLogoMediaResource(logo: string): Resource | null {
  if (!logo) {
    return null;
  }
  const k = logo.toLowerCase().trim();
  switch (k) {
    case 'apple': return $r('app.media.logo_apple');
    case 'canon': return $r('app.media.logo_canon');
    case 'casio': return $r('app.media.logo_casio');
    case 'dji': return $r('app.media.logo_dji');
    case 'fujifilm': return $r('app.media.logo_fujifilm');
    case 'gopro': return $r('app.media.logo_gopro');
    case 'hasselblad': return $r('app.media.logo_hasselblad');
    case 'honor': return $r('app.media.logo_honor');
    case 'huawei': return $r('app.media.logo_huawei');
    case 'insta360': return $r('app.media.logo_insta360');
    case 'kodak': return $r('app.media.logo_kodak');
    case 'konica_minolta': return $r('app.media.logo_konica_minolta');
    case 'leica': return $r('app.media.logo_leica');
    case 'lumix': return $r('app.media.logo_lumix');
    case 'mamiya': return $r('app.media.logo_mamiya');
    case 'master': return $r('app.media.logo_master');
    case 'nikon': return $r('app.media.logo_nikon');
    case 'olympus': return $r('app.media.logo_olympus');
    case 'oppo': return $r('app.media.logo_oppo');
    case 'panasonic': return $r('app.media.logo_panasonic');
    case 'pentax': return $r('app.media.logo_pentax');
    case 'phase_one': return $r('app.media.logo_phase_one');
    case 'polaroid': return $r('app.media.logo_polaroid');
    case 'ricoh': return $r('app.media.logo_ricoh');
    case 'rollei': return $r('app.media.logo_rollei');
    case 'samsung': return $r('app.media.logo_samsung');
    case 'sigma': return $r('app.media.logo_sigma');
    case 'sony': return $r('app.media.logo_sony');
    case 'tamron': return $r('app.media.logo_tamron');
    case 'vivo': return $r('app.media.logo_vivo');
    case 'xiaomi': return $r('app.media.logo_xiaomi');
    case 'xmage': return $r('app.media.logo_xmage');
    case 'zeiss': return $r('app.media.logo_zeiss');
    default: return null;
  }
}

/**
 * 官方正版 Logo 资产管理器：
 * 负责从应用资源包加载官方透明 PNG 并维护高频渲染内存缓存。
 */
export class LogoAssetManager {
  private static cache: Map<string, image.PixelMap> = new Map();
  private static whiteCache: Map<string, image.PixelMap> = new Map();
  private static loading: Map<string, Promise<image.PixelMap | null>> = new Map();

  /**
   * 同步获取已在内存中就绪的官方 Logo PixelMap（支持深底时通过 Canvas source-in 动态染白）
   */
  static getPixelMapSync(logo: string, isWhite: boolean = false): image.PixelMap | null {
    if (!logo || logo === 'none') {
      return null;
    }
    const key = logo.toLowerCase().trim();
    if (isWhite) {
      const cachedWhite = LogoAssetManager.whiteCache.get(key);
      if (cachedWhite) {
        return cachedWhite;
      }
      const orig = LogoAssetManager.cache.get(key);
      if (orig) {
        // 多彩标志（经典徕卡红圆标、蔡司蓝盾、柯达黄方标、宝丽来彩虹条）在深底保持经典原貌
        if (key === 'leica' || key === 'zeiss' || key === 'kodak' || key === 'polaroid') {
          return orig;
        }
        try {
          const aspect = LOGO_ASPECT_RATIOS[key] ?? 1.0;
          const w = 480;
          const h = Math.max(1, Math.round(480 / aspect));
          const off = new OffscreenCanvasRenderingContext2D(w, h, new RenderingContextSettings(true), LengthMetricsUnit.PX);
          off.drawImage(orig, 0, 0, w, h);
          off.globalCompositeOperation = 'source-in';
          off.fillStyle = '#FFFFFF';
          off.fillRect(0, 0, w, h);
          const whitePm = off.getPixelMap(0, 0, w, h);
          LogoAssetManager.whiteCache.set(key, whitePm);
          return whitePm;
        } catch (_) {
          return orig;
        }
      }
      return null;
    }
    return LogoAssetManager.cache.get(key) ?? null;
  }

  /**
   * 注册注入 PixelMap（可用于测试或手动挂载）
   */
  static setPixelMap(logo: string, pixelMap: image.PixelMap): void {
    if (logo && pixelMap) {
      LogoAssetManager.cache.set(logo.toLowerCase().trim(), pixelMap);
    }
  }

  /**
   * 计算指定高度下官方 Logo 的准确宽度
   */
  static getLogoWidth(logo: string, height: number): number {
    if (!logo || logo === 'none') {
      return 0;
    }
    const aspect = LOGO_ASPECT_RATIOS[logo.toLowerCase().trim()] ?? 1.0;
    return Math.round(height * aspect);
  }

  /**
   * 异步预载官方透明 PNG 并解码为 PixelMap 缓存
   */
  static async loadLogoPixelMap(logo: string, context?: common.UIAbilityContext): Promise<image.PixelMap | null> {
    if (!logo || logo === 'none') {
      return null;
    }
    const key = logo.toLowerCase().trim();
    if (LogoAssetManager.cache.has(key)) {
      return LogoAssetManager.cache.get(key)!;
    }
    if (LogoAssetManager.loading.has(key)) {
      return await LogoAssetManager.loading.get(key)!;
    }

    const res = getLogoMediaResource(key);
    if (!res) {
      return null;
    }

    const loadTask = (async (): Promise<image.PixelMap | null> => {
      try {
        let ctx = context;
        if (!ctx || !ctx.resourceManager) {
          return null;
        }
        const mediaBytes = await ctx.resourceManager.getMediaContent(res.id);
        const imageSource = image.createImageSource(mediaBytes.buffer);
        const pixelMap = await imageSource.createPixelMap();
        LogoAssetManager.cache.set(key, pixelMap);
        return pixelMap;
      } catch (err) {
        console.warn(`[LogoAssetManager] Failed to load official PNG logo for ${key}: ${JSON.stringify(err)}`);
        return null;
      } finally {
        LogoAssetManager.loading.delete(key);
      }
    })();

    LogoAssetManager.loading.set(key, loadTask);
    return await loadTask;
  }
}
