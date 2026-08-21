import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

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
    return destPath;
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
        return path;
      }
    }
    return `${workDir}/source.jpg`; // 默认返回
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
   * 复制文件
   */
  private static copyFile(src: string, dest: string): void {
    const srcFile = fs.openSync(src, fs.OpenMode.READ_ONLY);
    const destFile = fs.openSync(dest, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);

    const bufferSize = 4096;
    const buffer = new ArrayBuffer(bufferSize);
    let bytesRead: number = bufferSize;

    while (bytesRead === bufferSize) {
      bytesRead = fs.readSync(srcFile.fd, buffer);
      fs.writeSync(destFile.fd, buffer, { offset: 0, length: bytesRead });
    }

    fs.closeSync(srcFile.fd);
    fs.closeSync(destFile.fd);
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
}
