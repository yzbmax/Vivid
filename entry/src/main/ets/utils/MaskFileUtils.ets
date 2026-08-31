import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { WorkFileService } from '../services/WorkFileService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MaskFileUtils';

/**
 * 蒙版文件持久化（V2 §25）。
 *
 * 路径：filesDir/works/{workId}/subject-mask.bin
 * 文件布局（小端）：
 *   bytes 0~3   magic 'VMSK'
 *   bytes 4~7   version (uint32, 当前 1)
 *   bytes 8~11  width   (uint32)
 *   bytes 12~15 height  (uint32)
 *   bytes 16..  weights (uint8 × width×height)
 */

const MASK_MAGIC_0 = 0x56; // 'V'
const MASK_MAGIC_1 = 0x4D; // 'M'
const MASK_MAGIC_2 = 0x53; // 'S'
const MASK_MAGIC_3 = 0x4B; // 'K'
const MASK_VERSION: number = 1;
const HEADER_SIZE: number = 16;

/** 蒙版读取结果。 */
export interface MaskLoadResult {
  ok: boolean;
  width: number;
  height: number;
  weights: Uint8Array;
}

/** 单例防重写：同一 workId 的蒙版已落盘后跳过重复写入（V2 §29）。 */
export class MaskFileUtils {
  private static savedWorkIds: Set<string> = new Set<string>();

  /**
   * 保存蒙版；同一进程内同 workId 已保存过时直接返回路径（续编不重写）。
   *
   * @returns 蒙版文件的沙箱绝对路径
   */
  static async saveMaskIfNeeded(
    context: common.UIAbilityContext,
    workId: string,
    weights: Uint8Array,
    width: number,
    height: number
  ): Promise<string> {
    const path = `${WorkFileService.getWorkDir(context, workId)}/subject-mask.bin`;
    if (MaskFileUtils.savedWorkIds.has(workId)) {
      return path;
    }

    // 确保作品目录存在
    const dir = WorkFileService.getWorkDir(context, workId);
    if (!fs.accessSync(dir)) {
      fs.mkdirSync(dir, true);
    }

    const total = HEADER_SIZE + width * height;
    const buffer = new ArrayBuffer(total);
    const view = new DataView(buffer);
    view.setUint8(0, MASK_MAGIC_0);
    view.setUint8(1, MASK_MAGIC_1);
    view.setUint8(2, MASK_MAGIC_2);
    view.setUint8(3, MASK_MAGIC_3);
    view.setUint32(4, MASK_VERSION, true);
    view.setUint32(8, width, true);
    view.setUint32(12, height, true);
    new Uint8Array(buffer, HEADER_SIZE).set(weights);

    const file = fs.openSync(
      path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC
    );
    try {
      fs.writeSync(file.fd, buffer);
      MaskFileUtils.savedWorkIds.add(workId);
      hilog.info(0x0000, TAG, 'mask saved: %{public}s (%dx%d)', path, width, height);
    } finally {
      fs.closeSync(file.fd);
    }
    return path;
  }

  /**
   * 读取蒙版文件。缺失/魔数不符/版本不支持/尺寸与权重不一致 → ok=false。
   */
  static loadMask(path: string): MaskLoadResult {
    const bad: MaskLoadResult = { ok: false, width: 0, height: 0, weights: new Uint8Array(0) };
    if (!fs.accessSync(path)) {
      return bad;
    }
    let file: fs.File | null = null;
    try {
      const stat = fs.statSync(path);
      if (stat.size < HEADER_SIZE) {
        return bad;
      }
      file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      const bodySize = stat.size - HEADER_SIZE;
      const buffer = new ArrayBuffer(stat.size);
      const read = fs.readSync(file.fd, buffer);
      if (read < HEADER_SIZE) {
        return bad;
      }
      const view = new DataView(buffer);
      if (view.getUint8(0) !== MASK_MAGIC_0 || view.getUint8(1) !== MASK_MAGIC_1 ||
        view.getUint8(2) !== MASK_MAGIC_2 || view.getUint8(3) !== MASK_MAGIC_3) {
        return bad;
      }
      const version = view.getUint32(4, true);
      if (version !== MASK_VERSION) {
        return bad;
      }
      const width = view.getUint32(8, true);
      const height = view.getUint32(12, true);
      if (!(width > 0) || !(height > 0) || width * height !== bodySize) {
        return bad;
      }
      const weights = new Uint8Array(buffer, HEADER_SIZE, bodySize).slice();
      const good: MaskLoadResult = {
        ok: true,
        width: width,
        height: height,
        weights: weights
      };
      return good;
    } catch (_err) {
      return bad;
    } finally {
      if (file != null) {
        try {
          fs.closeSync(file.fd);
        } catch (_e) {
          // 忽略关闭异常
        }
      }
    }
  }

  /** 蒙版文件标准路径（编辑页续编校验用）。 */
  static maskPath(context: common.UIAbilityContext, workId: string): string {
    return `${WorkFileService.getWorkDir(context, workId)}/subject-mask.bin`;
  }

  /** 清除「已落盘」标记（测试用）。 */
  static resetSavedFlag(): void {
    MaskFileUtils.savedWorkIds.clear();
  }
}
