import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WorkRecord } from '../models/WorkRecord';

const TAG = 'WorkFileService';

/**
 * 作品文件服务：管理作品相关的本地文件。
 *
 * 职责：
 * 1. 将 PhotoPicker 选择的源图复制到应用沙箱
 * 2. 生成缩略图（预览图）
 * 3. 管理作品目录结构
 * 4. 清理临时文件
 *
 * 目录结构：
 * filesDir/
 *   works/
 *     {workId}/
 *       source.{ext}    - 源图
 *       preview.{ext}   - 缩略图
 */
export class WorkFileService {
  /**
   * 将源图复制到应用沙箱，返回稳定的本地 URI
   * @param context 应用上下文
   * @param workId 作品 ID
   * @param sourceUri PhotoPicker 返回的源图 URI
   * @returns 应用沙箱中的源图 URI
   */
  static async copySourceToSandbox(
    context: common.UIAbilityContext,
    workId: string,
    sourceUri: string
  ): Promise<string> {
    const workDir = WorkFileService.getWorkDir(context, workId);

    // 确保目录存在
    WorkFileService.ensureDir(workDir);

    // 从 URI 获取扩展名
    const ext = WorkFileService.getExtension(sourceUri);
    const destPath = `${workDir}/source${ext}`;

    // 复制文件
    WorkFileService.copyFile(sourceUri, destPath);

    hilog.info(0x0000, TAG, 'Source copied to sandbox: %{public}s', destPath);
    return `file://${destPath}`;
  }

  /**
   * 获取作品目录路径
   */
  static getWorkDir(context: common.UIAbilityContext, workId: string): string {
    return `${context.filesDir}/works/${workId}`;
  }

  /**
   * 获取源图路径
   */
  static getSourcePath(context: common.UIAbilityContext, workId: string): string {
    const workDir = WorkFileService.getWorkDir(context, workId);
    // 尝试常见扩展名
    const extensions = ['.jpg', '.jpeg', '.png', '.webp'];
    for (const ext of extensions) {
      const path = `${workDir}/source${ext}`;
      if (fs.accessSync(path)) {
        return `file://${path}`;
      }
    }
    return `file://${workDir}/source.jpg`; // 默认返回
  }

  /**
   * 检查作品源图是否存在
   */
  static hasSource(context: common.UIAbilityContext, workId: string): boolean {
    const workDir = WorkFileService.getWorkDir(context, workId);
    const extensions = ['.jpg', '.jpeg', '.png', '.webp'];
    for (const ext of extensions) {
      const path = `${workDir}/source${ext}`;
      if (fs.accessSync(path)) {
        return true;
      }
    }
    return false;
  }

  /**
   * 删除作品目录（单个文件操作，不递归）
   */
  static deleteWorkDir(context: common.UIAbilityContext, workId: string): void {
    const workDir = WorkFileService.getWorkDir(context, workId);
    const extensions = ['.jpg', '.jpeg', '.png', '.webp'];

    // 删除源图
    for (const ext of extensions) {
      const sourcePath = `${workDir}/source${ext}`;
      WorkFileService.safeUnlink(sourcePath);
    }

    // 删除预览图
    for (const ext of extensions) {
      const previewPath = `${workDir}/preview${ext}`;
      WorkFileService.safeUnlink(previewPath);
    }

    hilog.info(0x0000, TAG, 'Work dir cleaned: %{public}s', workDir);
  }

  /**
   * 保存作品渲染预览图到沙箱持久化目录
   * @param context 应用上下文
   * @param workId 作品 ID
   * @param sourceFilePath 渲染生成的临时图片路径或 URI
   * @returns 带有 file:// 前缀的标准持久化文件 URI
   */
  static savePreviewToSandbox(
    context: common.UIAbilityContext,
    workId: string,
    sourceFilePath: string
  ): string {
    const workDir = WorkFileService.getWorkDir(context, workId);
    WorkFileService.ensureDir(workDir);

    // 清理旧的 preview 文件以节省空间并避免缓存冲突
    WorkFileService.cleanOldPreviews(workDir);

    const now = Date.now();
    const ext = WorkFileService.getExtension(sourceFilePath);
    const destPath = `${workDir}/preview_${now}${ext}`;

    WorkFileService.copyFile(sourceFilePath, destPath);
    hilog.info(0x0000, TAG, 'Preview saved to sandbox: %{public}s', destPath);
    return `file://${destPath}`;
  }

  /**
   * 清理指定目录下的旧预览图
   */
  private static cleanOldPreviews(workDir: string): void {
    try {
      if (!fs.accessSync(workDir)) {
        return;
      }
      const filenames = fs.listFileSync(workDir);
      for (const fn of filenames) {
        if (fn.startsWith('preview')) {
          WorkFileService.safeUnlink(`${workDir}/${fn}`);
        }
      }
    } catch (_e) {
    }
  }

  /**
   * 复制文件
   */
  private static copyFile(src: string, dest: string): void {
    let cleanDest = dest;
    if (cleanDest.startsWith('file://')) {
      cleanDest = cleanDest.substring(7);
    }

    // 针对本地绝对路径优先直接路径复制
    let cleanSrc = src;
    if (cleanSrc.startsWith('file:///')) {
      cleanSrc = cleanSrc.substring(7);
    }
    if (cleanSrc.startsWith('/')) {
      try {
        fs.copyFileSync(cleanSrc, cleanDest);
        return;
      } catch (_err) {
      }
    }

    // fd 复制，通用兼容各类 URI（含 PhotoPicker 等 system provider URI）
    const srcFile = fs.openSync(src, fs.OpenMode.READ_ONLY);
    const destFile = fs.openSync(cleanDest, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
    try {
      fs.copyFileSync(srcFile.fd, destFile.fd);
    } finally {
      fs.closeSync(srcFile.fd);
      fs.closeSync(destFile.fd);
    }
  }

  /**
   * 确保目录存在
   */
  private static ensureDir(dir: string): void {
    if (!fs.accessSync(dir)) {
      fs.mkdirSync(dir, true);
    }
  }

  /**
   * 从文件路径或 URI 提取扩展名
   */
  private static getExtension(path: string): string {
    const lower = path.toLowerCase();
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.webp')) return '.webp';
    return '.jpg'; // 默认 JPEG
  }

  /**
   * 安全删除文件
   */
  private static safeUnlink(path: string): void {
    try {
      if (fs.accessSync(path)) {
        fs.unlinkSync(path);
      }
    } catch (_e) {
      // 忽略清理错误
    }
  }

  /**
   * 获取作品清单文件路径
   */
  static getManifestPath(context: common.UIAbilityContext): string {
    return `${context.filesDir}/works_manifest.json`;
  }

  /**
   * 保存作品清单到应用沙箱持久化存储（无大小限制，进程重启依然保持）
   */
  static saveWorksManifest(context: common.UIAbilityContext, works: WorkRecord[]): void {
    try {
      const manifestPath = WorkFileService.getManifestPath(context);
      const json = JSON.stringify(works);
      const file = fs.openSync(manifestPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, json);
      fs.closeSync(file);
      hilog.info(0x0000, TAG, 'Works manifest saved: %{public}d items', works.length);
    } catch (e) {
      hilog.error(0x0000, TAG, 'Failed to save works manifest: %{public}s', String(e));
    }
  }

  /**
   * 从应用沙箱持久化存储加载作品清单
   */
  static loadWorksManifest(context: common.UIAbilityContext): WorkRecord[] {
    try {
      const manifestPath = WorkFileService.getManifestPath(context);
      if (!fs.accessSync(manifestPath)) {
        return [];
      }
      const json = fs.readTextSync(manifestPath);
      if (!json || json.trim().length === 0) {
        return [];
      }
      const parsed = JSON.parse(json) as WorkRecord[];
      if (Array.isArray(parsed)) {
        hilog.info(0x0000, TAG, 'Works manifest loaded: %{public}d items', parsed.length);
        return parsed;
      }
      return [];
    } catch (e) {
      hilog.error(0x0000, TAG, 'Failed to load works manifest: %{public}s', String(e));
      return [];
    }
  }

  /**
   * 保存当前草稿到应用沙箱文件存储
   */
  static saveDraftFile(context: common.UIAbilityContext, draft: Object): void {
    try {
      const draftPath = `${context.filesDir}/current_draft.json`;
      const json = JSON.stringify(draft);
      const file = fs.openSync(draftPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, json);
      fs.closeSync(file);
      hilog.info(0x0000, TAG, 'Draft file saved to sandbox: %{public}s', draftPath);
    } catch (e) {
      hilog.error(0x0000, TAG, 'Failed to save draft file: %{public}s', String(e));
    }
  }

  /**
   * 从应用沙箱文件加载当前草稿
   */
  static loadDraftFile<T>(context: common.UIAbilityContext): T | null {
    try {
      const draftPath = `${context.filesDir}/current_draft.json`;
      if (!fs.accessSync(draftPath)) {
        return null;
      }
      const json = fs.readTextSync(draftPath);
      if (!json || json.trim().length === 0) {
        return null;
      }
      return JSON.parse(json) as T;
    } catch (e) {
      hilog.error(0x0000, TAG, 'Failed to load draft file: %{public}s', String(e));
      return null;
    }
  }

  /**
   * 清除沙箱草稿文件
   */
  static clearDraftFile(context: common.UIAbilityContext): void {
    try {
      const draftPath = `${context.filesDir}/current_draft.json`;
      if (fs.accessSync(draftPath)) {
        fs.unlinkSync(draftPath);
        hilog.info(0x0000, TAG, 'Draft file cleared from sandbox: %{public}s', draftPath);
      }
    } catch (e) {
      hilog.warn(0x0000, TAG, 'Failed to clear draft file: %{public}s', String(e));
    }
  }
}
