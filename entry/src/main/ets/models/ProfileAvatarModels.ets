import { AccountSettingsErrorCode } from './AccountSettingsModels';

/**
 * 相册头像上传契约。
 *
 * 头像 URI 独立于已冻结的 MockUser/AuthSession，仅由账号设置页与 Mock Store 使用。
 */
export interface ProfileAvatarUpdateRequest {
  nickname: string;
  avatarGlyph: string;
  avatarUri?: string;
}

export type ProfileAvatarUpdateErrorCode = AccountSettingsErrorCode | 'INVALID_AVATAR_URI';

export interface ProfileAvatarUpdateResult {
  success: boolean;
  errorCode?: ProfileAvatarUpdateErrorCode;
}
