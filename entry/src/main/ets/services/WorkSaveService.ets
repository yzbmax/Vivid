import { common } from '@kit.AbilityKit';
import { WorkRecord, WorkStatus } from '../models/WorkRecord';
import { AdjustParams } from '../models/EditModels';
import { mockWorkStore } from '../models/MockWorkStore';
import { AppSettingsStore } from '../models/AppSettingsStore';
import { ExportProfile, toExportProfile } from '../models/AppSettingsModels';
import { ImageRenderService } from './ImageRenderService';
import { PhotoExportService, ExportResult } from './PhotoExportService';
import { WorkFileService } from './WorkFileService';
import { generateWorkTitle } from '../models/WorkTitleGenerator';
import { generateWorkDescription } from '../models/WorkDescriptionGenerator';
import { EditorSnapshot, cloneEditorSnapshot, createDefaultEditorSnapshot } from '../models/SharedContracts';
import { EditorCompositionService } from './EditorCompositionService';

/**
 * 保存请求
 */
export interface WorkSaveRequest {
  /** 作品 ID；为空则新建 */
  workId?: string;
  /** 源图 URI（从 PhotoPicker 获取） */
  sourceImageUri: string;
  /** 调色参数 */
  adjustments: AdjustParams;
  /** 最后使用的工具 */
  lastTool: string;
  /** 保存模式：draft=草稿，sealed=正式保存 */
  mode: 'draft' | 'sealed';
  /** 0.1.9 新增：统一编辑快照 */
  editorSnapshot?: EditorSnapshot;
}

/**
 * 保存结果
 */
export interface WorkSaveResult {
  /** 是否成功 */
  success: boolean;
  /** 成功时返回作品记录 */
  work?: WorkRecord;
  /** 编码后的临时文件路径（sealed 模式下需要在 SaveButton 回调中使用） */
  cacheFilePath?: string;
  /** 失败时返回错误码 */
  errorCode?: 'SOURCE_UNAVAILABLE' | 'RENDER_FAILED' |
    'ENCODE_FAILED' | 'GALLERY_SAVE_FAILED' | 'WORK_WRITE_FAILED';
  /** 失败时返回错误信息 */
  errorMessage?: string;
}

/**
 * 作品保存服务：编排草稿保存、正式导出和作品仓库更新。
 *
 * 职责：
 * 1. 复制源图到应用沙箱
 * 2. 渲染调色后的图片
 * 3. 编码到 cacheDir（sealed 模式）
 * 4. 更新作品仓库
 *
 * 注意：正式保存需要两阶段调用：
 * 1. saveSealed() → 编码到 cacheDir，返回 cacheFilePath
 * 2. 在 SaveButton onClick 回调中调用 completeSealedExport() 写入相册
 */
export class WorkSaveService {
  private static saving: boolean = false;

  /**
   * 保存草稿
   * @param context 应用上下文
   * @param request 保存请求
   * @returns 保存结果
   */
  static async saveDraft(
    context: common.UIAbilityContext,
    request: WorkSaveRequest
  ): Promise<WorkSaveResult> {
    return WorkSaveService.save(context, request, 'draft');
  }

  /**
   * 正式保存（编码到 cacheDir，等待 SaveButton 回调写入相册）
   * @param context 应用上下文
   * @param request 保存请求
   * @returns 保存结果，包含 cacheFilePath
   */
  static async saveSealed(
    context: common.UIAbilityContext,
    request: WorkSaveRequest
  ): Promise<WorkSaveResult> {
    return WorkSaveService.save(context, request, 'sealed');
  }

  /**
   * 完成正式导出：在 SaveButton onClick 回调中调用
   * @param context 应用上下文
   * @param workId 作品 ID
   * @param cacheFilePath 编码后的临时文件路径
   * @returns 导出结果
   */
  static async completeSealedExport(
    context: common.UIAbilityContext,
    workId: string,
    cacheFilePath: string
  ): Promise<ExportResult> {
    const result = await PhotoExportService.saveViaSaveButton(context, cacheFilePath);

    if (result.success && result.mediaUri) {
      // 更新作品记录的 exportedAssetUri
      const work = mockWorkStore.findById(workId);
      if (work) {
        work.exportedAssetUri = result.mediaUri;
        mockWorkStore.update(workId, work);
      }
    }

    return result;
  }

  /**
   * 导出已有作品到相册（从作品菜单触发）
   * @param context 应用上下文
   * @param workId 作品 ID
   * @returns 导出结果，包含 cacheFilePath 供 SaveButton 使用
   */
  static async exportWork(
    context: common.UIAbilityContext,
    workId: string
  ): Promise<WorkSaveResult> {
    const work = mockWorkStore.findById(workId);
    if (!work) {
      return {
        success: false,
        errorCode: 'WORK_WRITE_FAILED',
        errorMessage: '作品不存在'
      };
    }

    if (!work.sourceImageUri) {
      return {
        success: false,
        errorCode: 'SOURCE_UNAVAILABLE',
        errorMessage: '作品源图不可用'
      };
    }

    try {
      // 获取导出配置
      const profile = await AppSettingsStore.getExportSettings();
      const exportProfile: ExportProfile = toExportProfile(profile);

      // 统一高清合成渲染（包含 LUT、调色、文字图层与边框）
      const snapshot = work.editorSnapshot ?? createDefaultEditorSnapshot();
      const compResult = await EditorCompositionService.render(
        work.sourceImageUri,
        work.adjustments,
        snapshot,
        exportProfile,
        false,
        context
      );

      // 编码到 cacheDir
      const cacheFilePath = await PhotoExportService.encodeToCacheFile(
        context, compResult.pixelMap, exportProfile
      );

      compResult.pixelMap.release();

      if (cacheFilePath === '') {
        return {
          success: false,
          errorCode: 'ENCODE_FAILED',
          errorMessage: '图片编码失败'
        };
      }

      return {
        success: true,
        work: work,
        cacheFilePath: cacheFilePath
      };
    } catch (_err) {
      return {
        success: false,
        errorCode: 'RENDER_FAILED',
        errorMessage: '图片渲染失败'
      };
    }
  }

  /**
   * 内部保存逻辑
   */
  private static async save(
    context: common.UIAbilityContext,
    request: WorkSaveRequest,
    mode: 'draft' | 'sealed'
  ): Promise<WorkSaveResult> {
    // 防重复点击
    if (WorkSaveService.saving) {
      return {
        success: false,
        errorCode: 'WORK_WRITE_FAILED',
        errorMessage: '保存操作正在进行中'
      };
    }

    WorkSaveService.saving = true;

    try {
      // 1. 复制源图到沙箱
      let workId = request.workId ?? '';
      let sourcePath: string;

      try {
        // 如果是新建，生成临时 ID
        if (!workId) {
          workId = `WORK-${Date.now()}`;
        }

        sourcePath = await WorkFileService.copySourceToSandbox(
          context, workId, request.sourceImageUri
        );
      } catch (_err) {
        return {
          success: false,
          errorCode: 'SOURCE_UNAVAILABLE',
          errorMessage: '源图复制失败'
        };
      }

      // 2. 渲染图片（仅正式保存需要渲染）
      let cacheFilePath: string | undefined;
      const previewUri = sourcePath;

      if (mode === 'sealed') {
        try {
          const profile = await AppSettingsStore.getExportSettings();
          const exportProfile: ExportProfile = toExportProfile(profile);

          const snapshot = request.editorSnapshot ?? createDefaultEditorSnapshot();
          const compResult = await EditorCompositionService.render(
            sourcePath,
            request.adjustments,
            snapshot,
            exportProfile,
            false,
            context
          );

          // 编码到 cacheDir
          cacheFilePath = await PhotoExportService.encodeToCacheFile(
            context, compResult.pixelMap, exportProfile
          );

          compResult.pixelMap.release();

          if (cacheFilePath === '') {
            return {
              success: false,
              errorCode: 'ENCODE_FAILED',
              errorMessage: '图片编码失败'
            };
          }
        } catch (_err) {
          return {
            success: false,
            errorCode: 'RENDER_FAILED',
            errorMessage: '图片渲染失败'
          };
        }
      }

      // 3. 创建或更新作品记录
      try {
        let work: WorkRecord;

        if (request.workId) {
          // 更新现有作品
          const existing = mockWorkStore.findById(request.workId);
          if (existing) {
            existing.sourceImageUri = sourcePath;
            existing.previewImageUri = previewUri;
            existing.adjustments.exposure = request.adjustments.exposure;
            existing.adjustments.brightness = request.adjustments.brightness;
            existing.adjustments.contrast = request.adjustments.contrast;
            existing.adjustments.saturation = request.adjustments.saturation;
            existing.lastTool = request.lastTool;
            existing.status = mode === 'sealed' ? WorkStatus.Sealed : WorkStatus.Draft;
            if (request.editorSnapshot !== undefined) {
              existing.editorSnapshot = cloneEditorSnapshot(request.editorSnapshot);
            }
            existing.updatedAt = Date.now();
            work = mockWorkStore.update(request.workId, existing);
          } else {
            return {
              success: false,
              errorCode: 'WORK_WRITE_FAILED',
              errorMessage: '作品不存在'
            };
          }
        } else {
          // 新建作品
          const newWork = new WorkRecord();
          const now = Date.now();
          newWork.title = generateWorkTitle(now, mockWorkStore.countToday());
          newWork.description = generateWorkDescription(request.adjustments, 0, 0);
          newWork.sourceImageUri = sourcePath;
          newWork.previewImageUri = previewUri;
          newWork.adjustments.exposure = request.adjustments.exposure;
          newWork.adjustments.brightness = request.adjustments.brightness;
          newWork.adjustments.contrast = request.adjustments.contrast;
          newWork.adjustments.saturation = request.adjustments.saturation;
          newWork.lastTool = request.lastTool;
          newWork.status = mode === 'sealed' ? WorkStatus.Sealed : WorkStatus.Draft;
          if (request.editorSnapshot !== undefined) {
            newWork.editorSnapshot = cloneEditorSnapshot(request.editorSnapshot);
          }
          work = mockWorkStore.create(newWork);
        }

        return {
          success: true,
          work: work,
          cacheFilePath: cacheFilePath
        };
      } catch (_err) {
        return {
          success: false,
          errorCode: 'WORK_WRITE_FAILED',
          errorMessage: '作品记录写入失败'
        };
      }
    } finally {
      WorkSaveService.saving = false;
    }
  }
}
