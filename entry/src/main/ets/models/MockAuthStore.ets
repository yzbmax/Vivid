import { AuthSession, MockUser } from './AuthModels';
import { validatePassword, validatePhone } from '../utils/AuthValidators';

export type AuthErrorCode = 'INVALID_PHONE' | 'INVALID_PASSWORD' | 'CODE_NOT_REQUESTED' |
  'CODE_PHONE_MISMATCH' | 'INVALID_CODE' | 'INVALID_CREDENTIALS' | 'PHONE_ALREADY_REGISTERED';

export interface RequestCodeResult {
  success: boolean;
  demoCode?: string;
  errorCode?: AuthErrorCode;
}

export interface AuthResult {
  success: boolean;
  session: AuthSession;
  errorCode?: AuthErrorCode;
}

interface MockUserAccount {
  phone: string;
  password: string;
  user: MockUser;
}

/**
 * 进程内 Mock 认证 Store。
 *
 * 账户、验证码和会话都不会写入持久化存储；密码只用于本轮演示比较。
 */
export class MockAuthStore {
  private static readonly DEMO_CODE: string = '123456';
  private static readonly DEMO_PHONE: string = '13800138000';
  private static readonly DEMO_PASSWORD: string = 'Vivid123';

  private static users: MockUserAccount[] = [
    {
      phone: MockAuthStore.DEMO_PHONE,
      password: MockAuthStore.DEMO_PASSWORD,
      user: {
        userId: 'MOCK-DEMO-USER',
        maskedPhone: '138****8000',
        nickname: '用户8000',
        avatarGlyph: '印'
      }
    }
  ];
  private static session: AuthSession = { status: 'anonymous' };
  private static pendingPhone: string = '';
  private static pendingCode: string = '';
  private static revision: number = 0;

  public static requestCode(phone: string): RequestCodeResult {
    if (validatePhone(phone).length > 0) {
      MockAuthStore.clearPendingCode();
      return { success: false, errorCode: 'INVALID_PHONE' };
    }
    MockAuthStore.pendingPhone = phone;
    MockAuthStore.pendingCode = MockAuthStore.DEMO_CODE;
    return { success: true, demoCode: MockAuthStore.DEMO_CODE };
  }

  public static loginWithCode(phone: string, code: string): AuthResult {
    if (validatePhone(phone).length > 0) {
      return MockAuthStore.failure('INVALID_PHONE');
    }
    if (MockAuthStore.pendingPhone.length === 0 || MockAuthStore.pendingCode.length === 0) {
      return MockAuthStore.failure('CODE_NOT_REQUESTED');
    }
    if (MockAuthStore.pendingPhone !== phone) {
      return MockAuthStore.failure('CODE_PHONE_MISMATCH');
    }
    if (MockAuthStore.pendingCode !== code) {
      return MockAuthStore.failure('INVALID_CODE');
    }

    const account: MockUserAccount | undefined = MockAuthStore.findAccount(phone);
    const user: MockUser = account === undefined
      ? MockAuthStore.createTemporaryUser(phone)
      : account.user;
    return MockAuthStore.authenticate(user);
  }

  public static loginWithPassword(phone: string, password: string): AuthResult {
    const account: MockUserAccount | undefined = MockAuthStore.findAccount(phone);
    if (account === undefined || account.password !== password) {
      return MockAuthStore.failure('INVALID_CREDENTIALS');
    }
    return MockAuthStore.authenticate(account.user);
  }

  public static register(phone: string, code: string, password: string): AuthResult {
    if (validatePhone(phone).length > 0) {
      return MockAuthStore.failure('INVALID_PHONE');
    }
    if (validatePassword(password).length > 0) {
      return MockAuthStore.failure('INVALID_PASSWORD');
    }
    if (MockAuthStore.findAccount(phone) !== undefined) {
      return MockAuthStore.failure('PHONE_ALREADY_REGISTERED');
    }
    if (MockAuthStore.pendingPhone.length === 0 || MockAuthStore.pendingCode.length === 0) {
      return MockAuthStore.failure('CODE_NOT_REQUESTED');
    }
    if (MockAuthStore.pendingPhone !== phone) {
      return MockAuthStore.failure('CODE_PHONE_MISMATCH');
    }
    if (MockAuthStore.pendingCode !== code) {
      return MockAuthStore.failure('INVALID_CODE');
    }

    const user: MockUser = MockAuthStore.createRegisteredUser(phone);
    MockAuthStore.users.push({ phone: phone, password: password, user: user });
    return MockAuthStore.authenticate(user);
  }

  public static getSession(): AuthSession {
    const user: MockUser | undefined = MockAuthStore.session.user;
    if (user === undefined) {
      return { status: 'anonymous' };
    }
    return { status: 'authenticated', user: MockAuthStore.copyUser(user) };
  }

  public static getCurrentUser(): MockUser | undefined {
    const user: MockUser | undefined = MockAuthStore.session.user;
    return user === undefined ? undefined : MockAuthStore.copyUser(user);
  }

  public static logout(): void {
    MockAuthStore.session = { status: 'anonymous' };
    MockAuthStore.clearPendingCode();
    MockAuthStore.bumpRevision();
  }

  private static findAccount(phone: string): MockUserAccount | undefined {
    return MockAuthStore.users.find((account: MockUserAccount) => account.phone === phone);
  }

  private static authenticate(user: MockUser): AuthResult {
    MockAuthStore.session = { status: 'authenticated', user: MockAuthStore.copyUser(user) };
    MockAuthStore.clearPendingCode();
    MockAuthStore.bumpRevision();
    return { success: true, session: MockAuthStore.getSession() };
  }

  private static failure(errorCode: AuthErrorCode): AuthResult {
    return { success: false, session: MockAuthStore.getSession(), errorCode: errorCode };
  }

  private static createTemporaryUser(phone: string): MockUser {
    return {
      userId: `MOCK-TEMP-${phone.substring(7)}`,
      maskedPhone: MockAuthStore.maskPhone(phone),
      nickname: `用户${phone.substring(7)}`,
      avatarGlyph: '印'
    };
  }

  private static createRegisteredUser(phone: string): MockUser {
    return {
      userId: `MOCK-USER-${phone.substring(7)}`,
      maskedPhone: MockAuthStore.maskPhone(phone),
      nickname: `用户${phone.substring(7)}`,
      avatarGlyph: '新'
    };
  }

  private static maskPhone(phone: string): string {
    return `${phone.substring(0, 3)}****${phone.substring(7)}`;
  }

  private static copyUser(user: MockUser): MockUser {
    return {
      userId: user.userId,
      maskedPhone: user.maskedPhone,
      nickname: user.nickname,
      avatarGlyph: user.avatarGlyph
    };
  }

  private static clearPendingCode(): void {
    MockAuthStore.pendingPhone = '';
    MockAuthStore.pendingCode = '';
  }

  private static bumpRevision(): void {
    MockAuthStore.revision += 1;
    AppStorage.setOrCreate('authRevision', MockAuthStore.revision);
  }
}
