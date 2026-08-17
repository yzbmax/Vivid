/**
 * 登录模块共享契约。
 *
 * 接口已在第 0 阶段冻结；后续如需变更，须由相关开发者共同确认。
 */
export interface MockUser {
  userId: string;
  maskedPhone: string;
  nickname: string;
  avatarGlyph: string;
}

export type AuthStatus = 'anonymous' | 'authenticated';

export interface AuthSession {
  status: AuthStatus;
  user?: MockUser;
}
