import { UIContext } from '@kit.ArkUI';

export interface TextFontRegistrationReport {
  registered: string[];
  failed: string[];
}

let customFontsRegistered: boolean = false;
let registeredFontKeys: string[] = [];

interface TextFontRegistration {
  key: string;
  family: string;
  source: Resource;
}

/** 在当前 UI 上下文中幂等注册文字字体；失败时只返回字体键，不记录用户内容。 */
export function registerTextFonts(uiContext: UIContext): TextFontRegistrationReport {
  const report: TextFontRegistrationReport = { registered: [], failed: [] };
  if (customFontsRegistered) {
    return report;
  }
  const manager = uiContext.getFont();
  const registrations: TextFontRegistration[] = [
    { key: 'noto_serif_sc', family: 'Noto Serif SC', source: $rawfile('fonts/notoserifsc.ttf') },
    { key: 'gkai', family: 'G Kai', source: $rawfile('fonts/gkai.ttf') },
    { key: 'noto_serif_latin', family: 'Noto Serif', source: $rawfile('fonts/notoserif.ttf') }
  ];
  for (let i = 0; i < registrations.length; i++) {
    const item = registrations[i];
    if (registeredFontKeys.indexOf(item.key) >= 0) {
      continue;
    }
    try {
      manager.registerFont({ familyName: item.family, familySrc: item.source });
      report.registered.push(item.key);
      registeredFontKeys.push(item.key);
    } catch (_err) {
      report.failed.push(item.key);
    }
  }
  if (report.failed.length === 0) {
    customFontsRegistered = true;
  }
  return report;
}
