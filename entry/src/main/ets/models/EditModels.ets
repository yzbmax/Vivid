/**
 * 编辑模块共享契约。
 *
 * 接口已在第 0 阶段冻结；后续如需变更，须由相关开发者共同确认。
 */
export enum EditEntrySource {
  Picker = 'picker',
  Work = 'work'
}

export interface EditRouteParams {
  source: EditEntrySource;
  imageUri?: string;
  workId?: string;
}

export interface AdjustParams {
  exposure: number;
  brightness: number;
  contrast: number;
  saturation: number;
}
