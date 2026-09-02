import {
  AppExportSettings,
  DEFAULT_EXPORT_SETTINGS,
  ExportFormat,
  ExportQuality
} from './AppSettingsModels';

const QUALITY_KEY: string = 'vivid.app-settings.export-quality';
const FORMAT_KEY: string = 'vivid.app-settings.export-format';

function normalizeExportQuality(value: string | undefined): ExportQuality {
  if (value === ExportQuality.High) {
    return ExportQuality.High;
  }
  if (value === ExportQuality.Ultra) {
    return ExportQuality.Ultra;
  }
  return ExportQuality.Standard;
}

function normalizeExportFormat(value: string | undefined): ExportFormat {
  if (value === ExportFormat.PNG) {
    return ExportFormat.PNG;
  }
  return ExportFormat.JPEG;
}

/**
 * Application-scoped export settings.
 *
 * PersistentStorage keeps the values across page instances and application
 * restarts while AppStorage provides the synchronous in-process view.
 */
export class AppSettingsStore {
  private static initialized: boolean = false;

  private static ensureInitialized(): void {
    if (AppSettingsStore.initialized) {
      return;
    }
    try {
      PersistentStorage.persistProp<string>(QUALITY_KEY, DEFAULT_EXPORT_SETTINGS.quality);
      PersistentStorage.persistProp<string>(FORMAT_KEY, DEFAULT_EXPORT_SETTINGS.format);
    } catch (err) {
      // Unit-test and non-UI contexts may not expose PersistentStorage. Keep
      // the same AppStorage contract so callers still receive safe defaults.
      if (!AppStorage.has(QUALITY_KEY)) {
        AppStorage.setOrCreate<string>(QUALITY_KEY, DEFAULT_EXPORT_SETTINGS.quality);
      }
      if (!AppStorage.has(FORMAT_KEY)) {
        AppStorage.setOrCreate<string>(FORMAT_KEY, DEFAULT_EXPORT_SETTINGS.format);
      }
    }
    AppSettingsStore.initialized = true;
  }

  public static async getExportSettings(): Promise<AppExportSettings> {
    AppSettingsStore.ensureInitialized();
    const qualityValue: string | undefined = AppStorage.get<string>(QUALITY_KEY);
    const formatValue: string | undefined = AppStorage.get<string>(FORMAT_KEY);
    return {
      quality: normalizeExportQuality(qualityValue),
      format: normalizeExportFormat(formatValue)
    };
  }

  public static async setExportQuality(value: ExportQuality): Promise<void> {
    AppSettingsStore.ensureInitialized();
    AppStorage.setOrCreate<string>(QUALITY_KEY, value);
  }

  public static async setExportFormat(value: ExportFormat): Promise<void> {
    AppSettingsStore.ensureInitialized();
    AppStorage.setOrCreate<string>(FORMAT_KEY, value);
  }

  /** Test-only reset; production pages never call this method. */
  public static async resetForTesting(): Promise<void> {
    try {
      PersistentStorage.deleteProp(QUALITY_KEY);
      PersistentStorage.deleteProp(FORMAT_KEY);
    } catch (err) {
      // PersistentStorage can be unavailable in pure unit-test contexts.
    }
    AppStorage.delete(QUALITY_KEY);
    AppStorage.delete(FORMAT_KEY);
    AppSettingsStore.initialized = false;
    AppSettingsStore.ensureInitialized();
  }

  /** Test-only corruption hook used to verify defensive fallback behavior. */
  public static setRawForTesting(quality: string, format: string): void {
    AppSettingsStore.ensureInitialized();
    AppStorage.setOrCreate<string>(QUALITY_KEY, quality);
    AppStorage.setOrCreate<string>(FORMAT_KEY, format);
  }
}
