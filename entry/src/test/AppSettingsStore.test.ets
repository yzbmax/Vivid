import { describe, it, expect } from '@ohos/hypium';
import {
  ExportFormat,
  ExportQuality,
  toExportProfile,
  estimateExportFileSize,
  formatEstimatedFileSize,
  resolveExportDimensions
} from '../main/ets/models/AppSettingsModels';
import { AppSettingsStore } from '../main/ets/models/AppSettingsStore';

export default function appSettingsStoreTest() {
  describe('appSettingsStoreTest', () => {
    it('returns standard JPEG by default', 0, async () => {
      await AppSettingsStore.resetForTesting();
      const settings = await AppSettingsStore.getExportSettings();
      expect(settings.quality).assertEqual(ExportQuality.Standard);
      expect(settings.format).assertEqual(ExportFormat.JPEG);
    });

    it('persists quality and format independently', 0, async () => {
      await AppSettingsStore.resetForTesting();
      await AppSettingsStore.setExportQuality(ExportQuality.Ultra);
      await AppSettingsStore.setExportFormat(ExportFormat.PNG);

      const settings = await AppSettingsStore.getExportSettings();
      expect(settings.quality).assertEqual(ExportQuality.Ultra);
      expect(settings.format).assertEqual(ExportFormat.PNG);
    });

    it('falls back to defaults for invalid stored values', 0, async () => {
      await AppSettingsStore.resetForTesting();
      AppSettingsStore.setRawForTesting('invalid-quality', 'invalid-format');

      const settings = await AppSettingsStore.getExportSettings();
      expect(settings.quality).assertEqual(ExportQuality.Standard);
      expect(settings.format).assertEqual(ExportFormat.JPEG);
    });

    it('maps standard JPEG to a 1920px profile', 0, () => {
      const profile = toExportProfile({
        quality: ExportQuality.Standard,
        format: ExportFormat.JPEG
      });
      expect(profile.mimeType).assertEqual('image/jpeg');
      expect(profile.extension).assertEqual('.jpg');
      expect(profile.maxLongEdge).assertEqual(1920);
      expect(profile.encoderQuality).assertEqual(85);
    });

    it('maps high JPEG to a 2560px profile', 0, () => {
      const profile = toExportProfile({
        quality: ExportQuality.High,
        format: ExportFormat.JPEG
      });
      expect(profile.maxLongEdge).assertEqual(2560);
      expect(profile.encoderQuality).assertEqual(92);
    });

    it('maps ultra JPEG to original size', 0, () => {
      const profile = toExportProfile({
        quality: ExportQuality.Ultra,
        format: ExportFormat.JPEG
      });
      expect(profile.maxLongEdge).assertEqual(0);
      expect(profile.encoderQuality).assertEqual(98);
    });

    it('maps all PNG profiles to lossless intent', 0, () => {
      const standard = toExportProfile({ quality: ExportQuality.Standard, format: ExportFormat.PNG });
      const high = toExportProfile({ quality: ExportQuality.High, format: ExportFormat.PNG });
      const ultra = toExportProfile({ quality: ExportQuality.Ultra, format: ExportFormat.PNG });

      expect(standard.mimeType).assertEqual('image/png');
      expect(standard.extension).assertEqual('.png');
      expect(standard.maxLongEdge).assertEqual(1920);
      expect(standard.encoderQuality).assertEqual(100);
      expect(high.maxLongEdge).assertEqual(2560);
      expect(high.encoderQuality).assertEqual(100);
      expect(ultra.maxLongEdge).assertEqual(0);
      expect(ultra.encoderQuality).assertEqual(100);
    });

    it('persists ORIGINAL, WEBP and HEIF format', 0, async () => {
      await AppSettingsStore.resetForTesting();
      await AppSettingsStore.setExportFormat(ExportFormat.ORIGINAL);
      let settings = await AppSettingsStore.getExportSettings();
      expect(settings.format).assertEqual(ExportFormat.ORIGINAL);

      await AppSettingsStore.setExportFormat(ExportFormat.WEBP);
      settings = await AppSettingsStore.getExportSettings();
      expect(settings.format).assertEqual(ExportFormat.WEBP);

      await AppSettingsStore.setExportFormat(ExportFormat.HEIF);
      settings = await AppSettingsStore.getExportSettings();
      expect(settings.format).assertEqual(ExportFormat.HEIF);
    });

    it('maps ORIGINAL format to source image format', 0, () => {
      const pngProfile = toExportProfile({ quality: ExportQuality.High, format: ExportFormat.ORIGINAL }, 'file:///cache/test.png');
      expect(pngProfile.mimeType).assertEqual('image/png');
      expect(pngProfile.extension).assertEqual('.png');

      const webpProfile = toExportProfile({ quality: ExportQuality.High, format: ExportFormat.ORIGINAL }, 'file:///cache/test.webp');
      expect(webpProfile.mimeType).assertEqual('image/webp');
      expect(webpProfile.extension).assertEqual('.webp');

      const heicProfile = toExportProfile({ quality: ExportQuality.High, format: ExportFormat.ORIGINAL }, 'file:///cache/photo.HEIC');
      expect(heicProfile.mimeType).assertEqual('image/heif');
      expect(heicProfile.extension).assertEqual('.heic');

      const jpegProfile = toExportProfile({ quality: ExportQuality.High, format: ExportFormat.ORIGINAL }, 'file:///cache/photo.jpg');
      expect(jpegProfile.mimeType).assertEqual('image/jpeg');
      expect(jpegProfile.extension).assertEqual('.jpg');

      const fallbackProfile = toExportProfile({ quality: ExportQuality.High, format: ExportFormat.ORIGINAL }, '');
      expect(fallbackProfile.mimeType).assertEqual('image/jpeg');
      expect(fallbackProfile.extension).assertEqual('.jpg');
    });

    it('estimates export file size across qualities and formats', 0, () => {
      // 12MP 图像基准测试
      const ultraJpeg = estimateExportFileSize(ExportQuality.Ultra, ExportFormat.JPEG, 4000, 3000);
      const highJpeg = estimateExportFileSize(ExportQuality.High, ExportFormat.JPEG, 4000, 3000);
      const stdJpeg = estimateExportFileSize(ExportQuality.Standard, ExportFormat.JPEG, 4000, 3000);

      expect(ultraJpeg > highJpeg).assertTrue();
      expect(highJpeg > stdJpeg).assertTrue();

      const ultraPng = estimateExportFileSize(ExportQuality.Ultra, ExportFormat.PNG, 4000, 3000);
      const ultraWebp = estimateExportFileSize(ExportQuality.Ultra, ExportFormat.WEBP, 4000, 3000);
      const ultraHeif = estimateExportFileSize(ExportQuality.Ultra, ExportFormat.HEIF, 4000, 3000);

      // PNG (无损) > JPEG > WebP > HEIF
      expect(ultraPng > ultraJpeg).assertTrue();
      expect(ultraJpeg > ultraWebp).assertTrue();
      expect(ultraWebp > ultraHeif).assertTrue();

      // ORIGINAL 动态推断尺寸
      const origPng = estimateExportFileSize(ExportQuality.Ultra, ExportFormat.ORIGINAL, 4000, 3000, 'img.png');
      expect(origPng).assertEqual(ultraPng);

      const origHeif = estimateExportFileSize(ExportQuality.Ultra, ExportFormat.ORIGINAL, 4000, 3000, 'img.heic');
      expect(origHeif).assertEqual(ultraHeif);
    });

    it('formats estimated file size in human readable KB and MB', 0, () => {
      expect(formatEstimatedFileSize(512 * 1024)).assertEqual('约 512 KB');
      expect(formatEstimatedFileSize(2.4 * 1024 * 1024)).assertEqual('约 2.4 MB');
      expect(formatEstimatedFileSize(14 * 1024 * 1024)).assertEqual('约 14.0 MB');
    });

    it('resolves export dimensions accurately for landscape and portrait', 0, () => {
      // 横屏 4000x3000
      const ultraLand = resolveExportDimensions(ExportQuality.Ultra, 4000, 3000);
      expect(ultraLand.width).assertEqual(4000);
      expect(ultraLand.height).assertEqual(3000);

      const highLand = resolveExportDimensions(ExportQuality.High, 4000, 3000);
      expect(highLand.width).assertEqual(2560);
      expect(highLand.height).assertEqual(1920);

      const stdLand = resolveExportDimensions(ExportQuality.Standard, 4000, 3000);
      expect(stdLand.width).assertEqual(1920);
      expect(stdLand.height).assertEqual(1440);

      // 竖屏 3000x4000
      const highPort = resolveExportDimensions(ExportQuality.High, 3000, 4000);
      expect(highPort.width).assertEqual(1920);
      expect(highPort.height).assertEqual(2560);

      // 小图无需放大，保持原尺寸
      const smallStd = resolveExportDimensions(ExportQuality.Standard, 1280, 720);
      expect(smallStd.width).assertEqual(1280);
      expect(smallStd.height).assertEqual(720);
    });
  });
}
