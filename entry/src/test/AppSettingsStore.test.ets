import { describe, it, expect } from '@ohos/hypium';
import {
  ExportFormat,
  ExportQuality,
  toExportProfile
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
  });
}
