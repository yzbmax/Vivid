import { AdjustParams } from './EditModels';
import { RegionAdjustParams } from './SharedContracts';

/**
 * 调色配方数据契约
 */
export interface ColorRecipe {
  /** 配方版本 */
  version: number;
  /** 配方名称 */
  name?: string;
  /** 全局调色参数 */
  adjustments: AdjustParams;
  /** 滤镜 ID */
  filterId: string;
  /** 滤镜强度 (0-1) */
  filterStrength: number;
  /** 主体/背景分区调色参数（若有） */
  regionAdjustments?: RegionAdjustParams;
  /** 复制时间戳 */
  timestamp: number;
}
