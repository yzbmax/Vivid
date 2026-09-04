import { describe, it, expect } from '@ohos/hypium';
import {
  BorderState,
  cloneBorderState,
  defaultBorderState,
  defaultWatermarkConfig,
  cloneWatermarkConfig,
  WatermarkConfig
} from '../main/ets/models/SharedContracts';
import {
  BORDER_TEMPLATES,
  findBorderTemplate,
  isWatermarkTemplate
} from '../main/ets/features/editor/border/BorderCatalog';
import {
  sanitizeBorderState,
  borderStateEquals,
  switchBorderTemplate
} from '../main/ets/features/editor/border/BorderState';
import {
  resolveBorderGeometry
} from '../main/ets/features/editor/border/BorderLayoutResolver';
import {
  formatFocalLength,
  formatFNumber,
  formatExposureTime,
  formatIso,
  formatExifDateTime
} from '../main/ets/features/editor/border/ExifFormatUtils';

export default function borderWatermarkTest() {
  describe('borderWatermarkTest', () => {
    it('registers camera_watermark in BORDER_TEMPLATES', 0, () => {
      const tpl = findBorderTemplate('camera_watermark');
      expect(tpl !== null).assertTrue();
      expect(tpl?.name).assertEqual('相机水印');
    });

    it('creates and deep-clones default watermark config', 0, () => {
      const cfg: WatermarkConfig = defaultWatermarkConfig();
      expect(cfg.showDevice).assertTrue();
      expect(cfg.showLogo).assertTrue();
      expect(cfg.showParams).assertTrue();
      expect(cfg.logo).assertEqual('zeiss');

      const cloned = cloneWatermarkConfig(cfg);
      expect(cloned.deviceModel).assertEqual(cfg.deviceModel);
      expect(cloned.paramsText).assertEqual(cfg.paramsText);

      // Verify mutation safety
      cfg.deviceModel = 'Modified Device';
      expect(cloned.deviceModel !== 'Modified Device').assertTrue();
    });

    it('preserves watermark in cloneBorderState and sanitizeBorderState', 0, () => {
      const border: BorderState = {
        templateId: 'camera_watermark',
        widthRatio: 0.08,
        colorArgb: 0xFFFFFFFF,
        shadowStrength: 0,
        watermark: {
          showDevice: true,
          deviceModel: 'HUAWEI Mate 60 Pro',
          showLogo: true,
          logo: 'xmage',
          showParams: true,
          paramsText: '50mm f/1.4 1/200s ISO100',
          showTime: true,
          timeText: '2026.09.03'
        }
      };

      const cloned = cloneBorderState(border);
      expect(cloned.watermark !== undefined).assertTrue();
      expect(cloned.watermark?.deviceModel).assertEqual('HUAWEI Mate 60 Pro');
      expect(cloned.watermark?.logo).assertEqual('xmage');

      const sanitized = sanitizeBorderState(border);
      expect(sanitized.templateId).assertEqual('camera_watermark');
      expect(sanitized.watermark?.paramsText).assertEqual('50mm f/1.4 1/200s ISO100');

      expect(borderStateEquals(border, cloned)).assertTrue();
    });

    it('resolves camera_watermark geometry with enlarged bottom banner', 0, () => {
      const border: BorderState = {
        templateId: 'camera_watermark',
        widthRatio: 0.08,
        colorArgb: 0xFFFFFFFF,
        shadowStrength: 0
      };

      const geom = resolveBorderGeometry({
        photoWidth: 1000,
        photoHeight: 800,
        border: border
      });

      expect(geom.templateId).assertEqual('camera_watermark');
      expect(geom.photoRect.width).assertEqual(1000);
      expect(geom.photoRect.height).assertEqual(800);
      // Bottom margin must be larger than top margin for the watermark banner
      expect(geom.insets.bottom > geom.insets.top).assertTrue();
      expect(geom.outputHeight).assertEqual(800 + geom.insets.top + geom.insets.bottom);
      expect(geom.outputWidth).assertEqual(1000 + geom.insets.left + geom.insets.right);
    });

    it('prioritizes 35mm equivalent focal length and handles fractions correctly', 0, () => {
      // 优先等效焦距（85mm，如 vivo 潜望长焦）
      expect(formatFocalLength('85', '14.5')).assertEqual('85mm');
      // 有理数分数形式（如 850/10）
      expect(formatFocalLength('850/10', '145/10')).assertEqual('85mm');
      // 缺少等效焦距时使用全画幅物理焦距
      expect(formatFocalLength('', '24')).assertEqual('24mm');
      // 缺少等效焦距时小底物理焦距保留1位小数
      expect(formatFocalLength('', '6.86')).assertEqual('6.9mm');

      // 光圈
      expect(formatFNumber('2.67')).assertEqual('f/2.67');
      expect(formatFNumber('267/100')).assertEqual('f/2.67');
      expect(formatFNumber('28/10')).assertEqual('f/2.8');

      // 快门（支持各类厂商格式并消除 sec. 冗余）
      expect(formatExposureTime('1/10')).assertEqual('1/10s');
      expect(formatExposureTime('1/1000 sec.')).assertEqual('1/1000s');
      expect(formatExposureTime('1/500 sec')).assertEqual('1/500s');
      expect(formatExposureTime('1/250s')).assertEqual('1/250s');
      expect(formatExposureTime('0.1')).assertEqual('1/10s');
      expect(formatExposureTime('2')).assertEqual('2s');

      // ISO
      expect(formatIso('10492')).assertEqual('ISO10492');

      // 时间
      expect(formatExifDateTime('2026:09:03 16:30:00')).assertEqual('2026.09.03 16:30');
    });

    it('registers all 9 new watermark templates in BORDER_TEMPLATES', 0, () => {
      const masterGrid = findBorderTemplate('watermark_master_grid');
      expect(masterGrid !== null).assertTrue();
      expect(masterGrid?.name).assertEqual('影展矩阵');

      const blurPip = findBorderTemplate('watermark_blur_pip');
      expect(blurPip !== null).assertTrue();
      expect(blurPip?.name).assertEqual('画中画虚化');

      const cinematic = findBorderTemplate('watermark_cinematic');
      expect(cinematic !== null).assertTrue();
      expect(cinematic?.name).assertEqual('电影影集');

      const retroFilm = findBorderTemplate('watermark_retro_film');
      expect(retroFilm !== null).assertTrue();
      expect(retroFilm?.name).assertEqual('复古胶片');

      const overlay = findBorderTemplate('watermark_overlay');
      expect(overlay !== null).assertTrue();
      expect(overlay?.name).assertEqual('无界悬浮');

      const nordic = findBorderTemplate('watermark_nordic_gallery');
      expect(nordic !== null).assertTrue();
      expect(nordic?.name).assertEqual('北欧画廊');

      const editorial = findBorderTemplate('watermark_editorial_mag');
      expect(editorial !== null).assertTrue();
      expect(editorial?.name).assertEqual('纪实画报');

      const contact = findBorderTemplate('watermark_contact_sheet');
      expect(contact !== null).assertTrue();
      expect(contact?.name).assertEqual('暗房印样');

      const oriental = findBorderTemplate('watermark_oriental_seal');
      expect(oriental !== null).assertTrue();
      expect(oriental?.name).assertEqual('文书印章');

      const stamp = findBorderTemplate('watermark_travel_stamp');
      expect(stamp !== null).assertTrue();
      expect(stamp?.name).assertEqual('齿孔邮票');

      const postcard = findBorderTemplate('watermark_travel_postcard');
      expect(postcard !== null).assertTrue();
      expect(postcard?.name).assertEqual('旅行明信片');

      const gradient = findBorderTemplate('watermark_gradient_frame');
      expect(gradient !== null).assertTrue();
      expect(gradient?.name).assertEqual('幻彩双色框');

      const leather = findBorderTemplate('watermark_leather_badge');
      expect(leather !== null).assertTrue();
      expect(leather?.name).assertEqual('皮革彩虹标');

      const mint = findBorderTemplate('watermark_mint_film');
      expect(mint !== null).assertTrue();
      expect(mint?.name).assertEqual('清新薄荷绿');

      const slim = findBorderTemplate('watermark_slim_white');
      expect(slim !== null).assertTrue();
      expect(slim?.name).assertEqual('极简细白条');
    });

    it('isWatermarkTemplate accurately identifies watermark templates', 0, () => {
      expect(isWatermarkTemplate('camera_watermark')).assertTrue();
      expect(isWatermarkTemplate('watermark_master_grid')).assertTrue();
      expect(isWatermarkTemplate('watermark_blur_pip')).assertTrue();
      expect(isWatermarkTemplate('watermark_cinematic')).assertTrue();
      expect(isWatermarkTemplate('watermark_retro_film')).assertTrue();
      expect(isWatermarkTemplate('watermark_overlay')).assertTrue();
      expect(isWatermarkTemplate('watermark_nordic_gallery')).assertTrue();
      expect(isWatermarkTemplate('watermark_editorial_mag')).assertTrue();
      expect(isWatermarkTemplate('watermark_contact_sheet')).assertTrue();
      expect(isWatermarkTemplate('watermark_oriental_seal')).assertTrue();
      expect(isWatermarkTemplate('watermark_travel_stamp')).assertTrue();
      expect(isWatermarkTemplate('watermark_travel_postcard')).assertTrue();
      expect(isWatermarkTemplate('watermark_gradient_frame')).assertTrue();
      expect(isWatermarkTemplate('watermark_leather_badge')).assertTrue();
      expect(isWatermarkTemplate('watermark_mint_film')).assertTrue();
      expect(isWatermarkTemplate('watermark_slim_white')).assertTrue();

      expect(isWatermarkTemplate('ink_black')).assertFalse();
      expect(isWatermarkTemplate('paper_white')).assertFalse();
      expect(isWatermarkTemplate('polaroid')).assertFalse();
      expect(isWatermarkTemplate('scroll_mount')).assertFalse();
      expect(isWatermarkTemplate('none')).assertFalse();
    });

    it('switchBorderTemplate sets signature default colors and initializes watermark', 0, () => {
      const initial = defaultBorderState();
      
      const sCinematic = switchBorderTemplate(initial, 'watermark_cinematic');
      expect(sCinematic.templateId).assertEqual('watermark_cinematic');
      expect(sCinematic.colorArgb).assertEqual(0xFF1A1A1A); // 电影墨黑
      expect(sCinematic.watermark !== undefined).assertTrue();

      const sRetro = switchBorderTemplate(initial, 'watermark_retro_film');
      expect(sRetro.templateId).assertEqual('watermark_retro_film');
      expect(sRetro.colorArgb).assertEqual(0xFFF5F2E8); // 复古温润相纸白
      expect(sRetro.watermark !== undefined).assertTrue();

      const sGrid = switchBorderTemplate(initial, 'watermark_master_grid');
      expect(sGrid.templateId).assertEqual('watermark_master_grid');
      expect(sGrid.colorArgb).assertEqual(0xFFFFFFFF);
      expect(sGrid.watermark !== undefined).assertTrue();

      const sNordic = switchBorderTemplate(initial, 'watermark_nordic_gallery');
      expect(sNordic.templateId).assertEqual('watermark_nordic_gallery');
      expect(sNordic.colorArgb).assertEqual(0xFFFFFFFF);

      const sEditorial = switchBorderTemplate(initial, 'watermark_editorial_mag');
      expect(sEditorial.templateId).assertEqual('watermark_editorial_mag');
      expect(sEditorial.colorArgb).assertEqual(0xFF1A1A1A);

      const sContact = switchBorderTemplate(initial, 'watermark_contact_sheet');
      expect(sContact.templateId).assertEqual('watermark_contact_sheet');
      expect(sContact.colorArgb).assertEqual(0xFF1A1A1A);

      const sOriental = switchBorderTemplate(initial, 'watermark_oriental_seal');
      expect(sOriental.templateId).assertEqual('watermark_oriental_seal');
      expect(sOriental.colorArgb).assertEqual(0xFFF7F4EB);
    });

    it('resolves geometry for watermark_master_grid with bottom parameters banner', 0, () => {
      const border: BorderState = {
        templateId: 'watermark_master_grid',
        widthRatio: 0.08,
        colorArgb: 0xFFFFFFFF,
        shadowStrength: 0
      };
      const geom = resolveBorderGeometry({ photoWidth: 1200, photoHeight: 800, border });
      expect(geom.templateId).assertEqual('watermark_master_grid');
      expect(geom.photoRect.width).assertEqual(1200);
      expect(geom.photoRect.height).assertEqual(800);
      expect(geom.insets.bottom > geom.insets.top).assertTrue();
      expect(geom.outputWidth).assertEqual(1200 + geom.insets.left + geom.insets.right);
      expect(geom.outputHeight).assertEqual(800 + geom.insets.top + geom.insets.bottom);
    });

    it('resolves geometry for watermark_blur_pip with balanced surrounding margins', 0, () => {
      const border: BorderState = {
        templateId: 'watermark_blur_pip',
        widthRatio: 0.08,
        colorArgb: 0xFFFFFFFF,
        shadowStrength: 0.2
      };
      const geom = resolveBorderGeometry({ photoWidth: 1000, photoHeight: 1500, border });
      expect(geom.templateId).assertEqual('watermark_blur_pip');
      expect(geom.insets.left > 0).assertTrue();
      expect(geom.insets.right > 0).assertTrue();
      expect(geom.insets.bottom > geom.insets.top).assertTrue();
      expect(geom.photoRect.x).assertEqual(geom.insets.left);
      expect(geom.photoRect.y).assertEqual(geom.insets.top);
    });

    it('resolves geometry for watermark_cinematic with letterbox aspect expansion', 0, () => {
      const border: BorderState = {
        templateId: 'watermark_cinematic',
        widthRatio: 0.08,
        colorArgb: 0xFF0D0D0D,
        shadowStrength: 0
      };
      const geom = resolveBorderGeometry({ photoWidth: 1000, photoHeight: 1000, border });
      expect(geom.templateId).assertEqual('watermark_cinematic');
      expect(geom.photoRect.width).assertEqual(1000);
      expect(geom.photoRect.height).assertEqual(1000);
      // Cinematic provides letterbox padding (insets.top and bottom)
      expect(geom.insets.top > 0).assertTrue();
      expect(geom.insets.bottom > 0).assertTrue();
    });

    it('resolves geometry for watermark_retro_film with instant-camera proportions', 0, () => {
      const border: BorderState = {
        templateId: 'watermark_retro_film',
        widthRatio: 0.08,
        colorArgb: 0xFFFBF8F1,
        shadowStrength: 0
      };
      const geom = resolveBorderGeometry({ photoWidth: 1000, photoHeight: 1000, border });
      expect(geom.templateId).assertEqual('watermark_retro_film');
      expect(geom.insets.bottom > geom.insets.top * 2).assertTrue();
      expect(geom.insets.left).assertEqual(geom.insets.right);
    });

    it('resolves geometry for watermark_overlay with strictly zero insets', 0, () => {
      const border: BorderState = {
        templateId: 'watermark_overlay',
        widthRatio: 0.08,
        colorArgb: 0xFFFFFFFF,
        shadowStrength: 0
      };
      const geom = resolveBorderGeometry({ photoWidth: 1920, photoHeight: 1080, border });
      expect(geom.templateId).assertEqual('watermark_overlay');
      expect(geom.insets.top).assertEqual(0);
      expect(geom.insets.bottom).assertEqual(0);
      expect(geom.insets.left).assertEqual(0);
      expect(geom.insets.right).assertEqual(0);
      expect(geom.outputWidth).assertEqual(1920);
      expect(geom.outputHeight).assertEqual(1080);
      expect(geom.photoRect.x).assertEqual(0);
      expect(geom.photoRect.y).assertEqual(0);
      expect(geom.photoRect.width).assertEqual(1920);
      expect(geom.photoRect.height).assertEqual(1080);
    });

    it('resolves geometry for watermark_nordic_gallery with wide bottom margin', 0, () => {
      const border: BorderState = {
        templateId: 'watermark_nordic_gallery',
        widthRatio: 0.08,
        colorArgb: 0xFFFFFFFF,
        shadowStrength: 0
      };
      const geom = resolveBorderGeometry({ photoWidth: 1000, photoHeight: 1000, border });
      expect(geom.templateId).assertEqual('watermark_nordic_gallery');
      expect(geom.insets.bottom > geom.insets.top).assertTrue();
      expect(geom.insets.left).assertEqual(geom.insets.right);
    });

    it('resolves geometry for watermark_editorial_mag with deep bottom magazine band', 0, () => {
      const border: BorderState = {
        templateId: 'watermark_editorial_mag',
        widthRatio: 0.08,
        colorArgb: 0xFF1A1A1A,
        shadowStrength: 0
      };
      const geom = resolveBorderGeometry({ photoWidth: 1200, photoHeight: 800, border });
      expect(geom.templateId).assertEqual('watermark_editorial_mag');
      expect(geom.insets.bottom > geom.insets.top * 2).assertTrue();
    });

    it('resolves geometry for watermark_contact_sheet with top film edge and bottom banner', 0, () => {
      const border: BorderState = {
        templateId: 'watermark_contact_sheet',
        widthRatio: 0.08,
        colorArgb: 0xFF1A1A1A,
        shadowStrength: 0
      };
      const geom = resolveBorderGeometry({ photoWidth: 1000, photoHeight: 1500, border });
      expect(geom.templateId).assertEqual('watermark_contact_sheet');
      expect(geom.insets.top > 0).assertTrue();
      expect(geom.insets.bottom > geom.insets.top).assertTrue();
    });

    it('resolves geometry for watermark_oriental_seal with seal bottom margin', 0, () => {
      const border: BorderState = {
        templateId: 'watermark_oriental_seal',
        widthRatio: 0.08,
        colorArgb: 0xFFF7F4EB,
        shadowStrength: 0
      };
      const geom = resolveBorderGeometry({ photoWidth: 1000, photoHeight: 1000, border });
      expect(geom.templateId).assertEqual('watermark_oriental_seal');
      expect(geom.insets.bottom > geom.insets.top).assertTrue();
      expect(geom.insets.left).assertEqual(geom.insets.right);
    });

    it('supports all 16 logo types in watermark config without corruption', 0, () => {
      const logos = [
        'zeiss', 'leica', 'hasselblad', 'xmage', 'fujifilm',
        'xiaomi', 'huawei', 'apple', 'samsung', 'vivo',
        'oppo', 'honor', 'sony', 'canon', 'nikon', 'master', 'none'
      ];
      for (const l of logos) {
        const cfg = defaultWatermarkConfig();
        cfg.logo = l as any;
        const cloned = cloneWatermarkConfig(cfg);
        expect(cloned.logo).assertEqual(l);
      }
    });
  });
}
