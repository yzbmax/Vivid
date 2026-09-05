import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

/**
 * 首选项通用存储工具
 *
 * 依据：华为 HarmonyOS NEXT @kit.ArkData preferences 开发指南。
 * 特性：
 * 1. 优先使用 @kit.ArkData 原生 preferences 读写与持久化；
 * 2. 具备内存缓存与脱机降级机制，纯 Node.js/单测环境下无缝 fallback 至内存 Map；
 * 3. 支持泛型 JSON 序列化存储与异步 flush()。
 */
export class PreferencesHelper {
  private static instanceMap: Map<string, PreferencesHelper> = new Map<string, PreferencesHelper>();
  private storeName: string;
  private prefInstance: preferences.Preferences | null = null;
  private memoryCache: Map<string, string> = new Map<string, string>();
  private initialized: boolean = false;

  private constructor(name: string) {
    this.storeName = name;
  }

  public static getStore(name: string = 'vivid_default_pref'): PreferencesHelper {
    let helper = PreferencesHelper.instanceMap.get(name);
    if (!helper) {
      helper = new PreferencesHelper(name);
      PreferencesHelper.instanceMap.set(name, helper);
    }
    return helper;
  }

  public async init(context?: common.UIAbilityContext): Promise<void> {
    if (this.initialized && this.prefInstance !== null) {
      return;
    }
    try {
      if (context) {
        this.prefInstance = await preferences.getPreferences(context, this.storeName);
      } else {
        const appContext = AppStorage.get<common.UIAbilityContext>('appContext');
        if (appContext) {
          this.prefInstance = await preferences.getPreferences(appContext, this.storeName);
        }
      }
    } catch (_err) {
      // 在单测或无 AbilityKit 环境下安全降级使用内存 Map
      this.prefInstance = null;
    }
    this.initialized = true;
  }

  public async putString(key: string, value: string): Promise<void> {
    this.memoryCache.set(key, value);
    if (this.prefInstance) {
      try {
        await this.prefInstance.put(key, value);
        await this.prefInstance.flush();
      } catch (_err) {
        // 异常降级在内存中保留
      }
    }
  }

  public async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (this.prefInstance) {
      try {
        const val = await this.prefInstance.get(key, defaultValue);
        const strVal = String(val ?? defaultValue);
        this.memoryCache.set(key, strVal);
        return strVal;
      } catch (_err) {
        // 异常降级读取内存
      }
    }
    return this.memoryCache.get(key) ?? defaultValue;
  }

  public async putObject<T>(key: string, value: T): Promise<void> {
    const json = JSON.stringify(value);
    await this.putString(key, json);
  }

  public async getObject<T>(key: string, defaultValue: T): Promise<T> {
    const json = await this.getString(key, '');
    if (!json) {
      return defaultValue;
    }
    try {
      return JSON.parse(json) as T;
    } catch (_err) {
      return defaultValue;
    }
  }

  public async delete(key: string): Promise<void> {
    this.memoryCache.delete(key);
    if (this.prefInstance) {
      try {
        await this.prefInstance.delete(key);
        await this.prefInstance.flush();
      } catch (_err) {
      }
    }
  }

  public async clear(): Promise<void> {
    this.memoryCache.clear();
    if (this.prefInstance) {
      try {
        await this.prefInstance.clear();
        await this.prefInstance.flush();
      } catch (_err) {
      }
    }
  }
}
