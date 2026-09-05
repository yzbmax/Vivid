/**
 * 用户资料与账号安全增补契约。
 *
 * 本文件中的名称在本轮创建后冻结；不得复用或重声明 AuthModels.ets 中的既有契约。
 */

export type AccountSettingsErrorCode =
  | 'INVALID_NICKNAME'
  | 'INVALID_AVATAR_GLYPH'
  | 'INVALID_PHONE'
  | 'INVALID_CODE'
  | 'CODE_NOT_REQUESTED'
  | 'CODE_PHONE_MISMATCH'
  | 'CODE_PURPOSE_MISMATCH'
  | 'CODE_ALREADY_CONSUMED'
  | 'SAME_PHONE'
  | 'PHONE_ALREADY_BOUND'
  | 'PASSWORD_NOT_SET'
  | 'PASSWORD_ALREADY_SET'
  | 'INVALID_PASSWORD'
  | 'INCORRECT_CURRENT_PASSWORD'
  | 'SAME_PASSWORD'
  | 'NOT_AUTHENTICATED'
  | 'INVALID_CREDENTIALS'
  | 'CLOSURE_NOT_VERIFIED';

export interface AccountSecuritySnapshot {
  maskedPhone: string;
  hasPassword: boolean;
}

export interface ProfileUpdateRequest {
  nickname: string;
  avatarGlyph: string;
}

export interface PhoneBindingChangeRequest {
  newPhone: string;
  code: string;
}

export interface PasswordSetupRequest {
  code: string;
  newPassword: string;
}

export interface PasswordChangeRequest {
  currentPassword: string;
  newPassword: string;
}

export type AccountClosureMethod = 'password' | 'code';

export interface AccountClosureVerification {
  method: AccountClosureMethod;
  credential: string;
}

export interface AccountSettingsResult {
  success: boolean;
  errorCode?: AccountSettingsErrorCode;
}

export interface SettingsCodeRequestResult {
  success: boolean;
  demoCode?: string;
  errorCode?: AccountSettingsErrorCode;
}
