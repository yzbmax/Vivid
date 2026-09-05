import { AuthSession, MockUser } from './AuthModels';
import {
  AccountClosureVerification,
  AccountSecuritySnapshot,
  AccountSettingsErrorCode,
  AccountSettingsResult,
  PasswordChangeRequest,
  PasswordSetupRequest,
  PhoneBindingChangeRequest,
  ProfileUpdateRequest,
  SettingsCodeRequestResult
} from './AccountSettingsModels';
import {
  ProfileAvatarUpdateErrorCode,
  ProfileAvatarUpdateRequest,
  ProfileAvatarUpdateResult
} from './ProfileAvatarModels';
import { validatePassword, validatePhone } from '../utils/AuthValidators';

export type AuthErrorCode = 'INVALID_PHONE' | 'INVALID_PASSWORD' | 'CODE_NOT_REQUESTED' |
  'CODE_PHONE_MISMATCH' | 'CODE_PURPOSE_MISMATCH' | 'CODE_ALREADY_CONSUMED' | 'INVALID_CODE' |
  'INVALID_CREDENTIALS' | 'PHONE_ALREADY_REGISTERED';

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

interface MockAccountRecord {
  accountId: string;
  phone: string;
  password?: string;
  nickname: string;
  avatarGlyph: string;
  avatarUri?: string;
}

type MockCodePurpose = 'LOGIN' | 'REGISTRATION' | 'PHONE_BINDING' | 'PASSWORD_SETUP' | 'ACCOUNT_CLOSURE';

interface MockCodeChallenge {
  phone: string;
  purpose: MockCodePurpose;
  code: string;
  consumed: boolean;
}

interface AccountClosureAuthorization {
  verified: boolean;
  issuedAt: number;
  accountId: string;
}

/**
 * 进程内 Mock 认证与账号设置 Store。
 *
 * 账户、验证码和会话都不会写入持久化存储；密码只用于本轮演示比较。
 */
export class MockAuthStore {
  private static readonly DEMO_CODE: string = '123456';
  private static readonly DEMO_PHONE: string = '13800138000';
  private static readonly DEMO_PASSWORD: string = 'Vivid123';

  private static readonly AVATAR_GLYPHS: string[] = ['印', '墨', '朱', '卷', '砚', '山'];

  private static users: MockAccountRecord[] = [
    {
      accountId: 'MOCK-ACCOUNT-1',
      phone: MockAuthStore.DEMO_PHONE,
      password: MockAuthStore.DEMO_PASSWORD,
      nickname: '用户8000',
      avatarGlyph: '印'
    }
  ];
  private static nextAccountNumber: number = 2;
  private static currentAccountId: string = '';
  private static challenges: MockCodeChallenge[] = [];
  private static closureAuthorization: AccountClosureAuthorization | undefined = undefined;

  public static requestCode(phone: string): RequestCodeResult {
    return MockAuthStore.requestAuthCode(phone, 'LOGIN');
  }

  public static requestRegistrationCode(phone: string): RequestCodeResult {
    return MockAuthStore.requestAuthCode(phone, 'REGISTRATION');
  }

  public static loginWithCode(phone: string, code: string): AuthResult {
    if (validatePhone(phone).length > 0) {
      return MockAuthStore.failure('INVALID_PHONE');
    }
    const challengeError: AccountSettingsErrorCode | undefined =
      MockAuthStore.consumeChallenge(phone, 'LOGIN', code);
    if (challengeError !== undefined) {
      return MockAuthStore.failure(MockAuthStore.toAuthErrorCode(challengeError));
    }

    let account: MockAccountRecord | undefined = MockAuthStore.findAccountByPhone(phone);
    if (account === undefined) {
      account = MockAuthStore.createAccount(phone, undefined);
      MockAuthStore.users.push(account);
    }
    return MockAuthStore.authenticate(account.accountId);
  }

  public static loginWithPassword(phone: string, password: string): AuthResult {
    const account: MockAccountRecord | undefined = MockAuthStore.findAccountByPhone(phone);
    if (account === undefined || account.password === undefined || account.password !== password) {
      return MockAuthStore.failure('INVALID_CREDENTIALS');
    }
    return MockAuthStore.authenticate(account.accountId);
  }

  public static register(phone: string, code: string, password: string): AuthResult {
    if (validatePhone(phone).length > 0) {
      return MockAuthStore.failure('INVALID_PHONE');
    }
    if (validatePassword(password).length > 0) {
      return MockAuthStore.failure('INVALID_PASSWORD');
    }
    if (MockAuthStore.findAccountByPhone(phone) !== undefined) {
      return MockAuthStore.failure('PHONE_ALREADY_REGISTERED');
    }
    const challengeError: AccountSettingsErrorCode | undefined =
      MockAuthStore.consumeChallenge(phone, 'REGISTRATION', code);
    if (challengeError !== undefined) {
      return MockAuthStore.failure(MockAuthStore.toAuthErrorCode(challengeError));
    }

    const account: MockAccountRecord = MockAuthStore.createAccount(phone, password);
    MockAuthStore.users.push(account);
    return MockAuthStore.authenticate(account.accountId);
  }

  public static getSession(): AuthSession {
    const user: MockUser | undefined = MockAuthStore.getCurrentUser();
    if (user === undefined) {
      return { status: 'anonymous' };
    }
    return { status: 'authenticated', user: user };
  }

  public static getCurrentUser(): MockUser | undefined {
    const account: MockAccountRecord | undefined = MockAuthStore.findAccountById(MockAuthStore.currentAccountId);
    return account === undefined ? undefined : MockAuthStore.projectUser(account);
  }

  public static getAccountSecuritySnapshot(): AccountSecuritySnapshot | undefined {
    const account: MockAccountRecord | undefined = MockAuthStore.currentAccount();
    if (account === undefined) {
      return undefined;
    }
    return {
      maskedPhone: MockAuthStore.maskPhone(account.phone),
      hasPassword: account.password !== undefined
    };
  }

  public static getCurrentAvatarUri(): string | undefined {
    return MockAuthStore.currentAccount()?.avatarUri;
  }

  public static logout(): void {
    MockAuthStore.currentAccountId = '';
    MockAuthStore.clearChallenges();
    MockAuthStore.clearClosureAuthorization();
  }

  public static updateProfile(request: ProfileUpdateRequest): AccountSettingsResult {
    const account: MockAccountRecord | undefined = MockAuthStore.currentAccount();
    if (account === undefined) {
      return MockAuthStore.settingsFailure('NOT_AUTHENTICATED');
    }
    const nickname: string = request.nickname.trim();
    const validationError: AccountSettingsErrorCode | undefined =
      MockAuthStore.validateProfileFields(nickname, request.avatarGlyph);
    if (validationError !== undefined) {
      return MockAuthStore.settingsFailure(validationError);
    }
    account.nickname = nickname;
    account.avatarGlyph = request.avatarGlyph;
    MockAuthStore.clearClosureAuthorization();
    return { success: true };
  }

  public static updateProfileWithAvatar(request: ProfileAvatarUpdateRequest): ProfileAvatarUpdateResult {
    const account: MockAccountRecord | undefined = MockAuthStore.currentAccount();
    if (account === undefined) {
      return MockAuthStore.profileAvatarFailure('NOT_AUTHENTICATED');
    }
    const nickname: string = request.nickname.trim();
    const validationError: AccountSettingsErrorCode | undefined =
      MockAuthStore.validateProfileFields(nickname, request.avatarGlyph);
    if (validationError !== undefined) {
      return MockAuthStore.profileAvatarFailure(validationError);
    }

    let normalizedAvatarUri: string | undefined = undefined;
    if (request.avatarUri !== undefined) {
      normalizedAvatarUri = request.avatarUri.trim();
      if (normalizedAvatarUri.length === 0) {
        return MockAuthStore.profileAvatarFailure('INVALID_AVATAR_URI');
      }
    }

    account.nickname = nickname;
    account.avatarGlyph = request.avatarGlyph;
    if (normalizedAvatarUri !== undefined) {
      account.avatarUri = normalizedAvatarUri;
    }
    MockAuthStore.clearClosureAuthorization();
    return { success: true };
  }

  public static requestPhoneBindingCode(newPhone: string): SettingsCodeRequestResult {
    const account: MockAccountRecord | undefined = MockAuthStore.currentAccount();
    if (account === undefined) {
      return MockAuthStore.settingsCodeFailure('NOT_AUTHENTICATED');
    }
    if (validatePhone(newPhone).length > 0) {
      return MockAuthStore.settingsCodeFailure('INVALID_PHONE');
    }
    if (account.phone === newPhone) {
      return MockAuthStore.settingsCodeFailure('SAME_PHONE');
    }
    const existing: MockAccountRecord | undefined = MockAuthStore.findAccountByPhone(newPhone);
    if (existing !== undefined && existing.accountId !== account.accountId) {
      return MockAuthStore.settingsCodeFailure('PHONE_ALREADY_BOUND');
    }
    return MockAuthStore.requestSettingsCode(newPhone, 'PHONE_BINDING');
  }

  public static changePhoneBinding(request: PhoneBindingChangeRequest): AccountSettingsResult {
    const account: MockAccountRecord | undefined = MockAuthStore.currentAccount();
    if (account === undefined) {
      return MockAuthStore.settingsFailure('NOT_AUTHENTICATED');
    }
    if (validatePhone(request.newPhone).length > 0) {
      return MockAuthStore.settingsFailure('INVALID_PHONE');
    }
    if (account.phone === request.newPhone) {
      return MockAuthStore.settingsFailure('SAME_PHONE');
    }
    const existing: MockAccountRecord | undefined = MockAuthStore.findAccountByPhone(request.newPhone);
    if (existing !== undefined && existing.accountId !== account.accountId) {
      return MockAuthStore.settingsFailure('PHONE_ALREADY_BOUND');
    }
    const challengeError: AccountSettingsErrorCode | undefined =
      MockAuthStore.consumeChallenge(request.newPhone, 'PHONE_BINDING', request.code);
    if (challengeError !== undefined) {
      return MockAuthStore.settingsFailure(challengeError);
    }
    account.phone = request.newPhone;
    MockAuthStore.clearClosureAuthorization();
    return { success: true };
  }

  public static requestPasswordSetupCode(): SettingsCodeRequestResult {
    const account: MockAccountRecord | undefined = MockAuthStore.currentAccount();
    if (account === undefined) {
      return MockAuthStore.settingsCodeFailure('NOT_AUTHENTICATED');
    }
    if (account.password !== undefined) {
      return MockAuthStore.settingsCodeFailure('PASSWORD_ALREADY_SET');
    }
    return MockAuthStore.requestSettingsCode(account.phone, 'PASSWORD_SETUP');
  }

  public static setupPassword(request: PasswordSetupRequest): AccountSettingsResult {
    const account: MockAccountRecord | undefined = MockAuthStore.currentAccount();
    if (account === undefined) {
      return MockAuthStore.settingsFailure('NOT_AUTHENTICATED');
    }
    if (account.password !== undefined) {
      return MockAuthStore.settingsFailure('PASSWORD_ALREADY_SET');
    }
    if (validatePassword(request.newPassword).length > 0) {
      return MockAuthStore.settingsFailure('INVALID_PASSWORD');
    }
    const challengeError: AccountSettingsErrorCode | undefined =
      MockAuthStore.consumeChallenge(account.phone, 'PASSWORD_SETUP', request.code);
    if (challengeError !== undefined) {
      return MockAuthStore.settingsFailure(challengeError);
    }
    account.password = request.newPassword;
    MockAuthStore.clearClosureAuthorization();
    return { success: true };
  }

  public static changePassword(request: PasswordChangeRequest): AccountSettingsResult {
    const account: MockAccountRecord | undefined = MockAuthStore.currentAccount();
    if (account === undefined) {
      return MockAuthStore.settingsFailure('NOT_AUTHENTICATED');
    }
    if (account.password === undefined) {
      return MockAuthStore.settingsFailure('PASSWORD_NOT_SET');
    }
    if (account.password !== request.currentPassword) {
      return MockAuthStore.settingsFailure('INCORRECT_CURRENT_PASSWORD');
    }
    if (validatePassword(request.newPassword).length > 0) {
      return MockAuthStore.settingsFailure('INVALID_PASSWORD');
    }
    if (account.password === request.newPassword) {
      return MockAuthStore.settingsFailure('SAME_PASSWORD');
    }
    account.password = request.newPassword;
    MockAuthStore.clearClosureAuthorization();
    return { success: true };
  }

  public static requestAccountClosureCode(): SettingsCodeRequestResult {
    const account: MockAccountRecord | undefined = MockAuthStore.currentAccount();
    if (account === undefined) {
      return MockAuthStore.settingsCodeFailure('NOT_AUTHENTICATED');
    }
    return MockAuthStore.requestSettingsCode(account.phone, 'ACCOUNT_CLOSURE');
  }

  public static verifyAccountClosure(verification: AccountClosureVerification): AccountSettingsResult {
    const account: MockAccountRecord | undefined = MockAuthStore.currentAccount();
    MockAuthStore.clearClosureAuthorization();
    if (account === undefined) {
      return MockAuthStore.settingsFailure('NOT_AUTHENTICATED');
    }
    if (verification.method === 'password') {
      if (account.password === undefined) {
        return MockAuthStore.settingsFailure('PASSWORD_NOT_SET');
      }
      if (account.password !== verification.credential) {
        return MockAuthStore.settingsFailure('INVALID_CREDENTIALS');
      }
    } else {
      const challengeError: AccountSettingsErrorCode | undefined =
        MockAuthStore.consumeChallenge(account.phone, 'ACCOUNT_CLOSURE', verification.credential);
      if (challengeError !== undefined) {
        return MockAuthStore.settingsFailure(challengeError);
      }
    }
    MockAuthStore.closureAuthorization = {
      verified: true,
      issuedAt: Date.now(),
      accountId: account.accountId
    };
    return { success: true };
  }

  public static cancelAccountClosure(): void {
    MockAuthStore.clearClosureAuthorization();
  }

  public static closeAccount(): AccountSettingsResult {
    const authorization: AccountClosureAuthorization | undefined = MockAuthStore.closureAuthorization;
    MockAuthStore.clearClosureAuthorization();
    if (authorization === undefined || !authorization.verified || authorization.accountId !== MockAuthStore.currentAccountId) {
      return MockAuthStore.settingsFailure('CLOSURE_NOT_VERIFIED');
    }
    const accountIndex: number = MockAuthStore.users.findIndex(
      (account: MockAccountRecord) => account.accountId === authorization.accountId
    );
    if (accountIndex < 0) {
      return MockAuthStore.settingsFailure('CLOSURE_NOT_VERIFIED');
    }
    MockAuthStore.users.splice(accountIndex, 1);
    MockAuthStore.currentAccountId = '';
    MockAuthStore.clearChallenges();
    return { success: true };
  }

  private static requestAuthCode(phone: string, purpose: MockCodePurpose): RequestCodeResult {
    if (validatePhone(phone).length > 0) {
      MockAuthStore.clearChallenge(purpose);
      return { success: false, errorCode: 'INVALID_PHONE' };
    }
    MockAuthStore.setChallenge(phone, purpose);
    return { success: true, demoCode: MockAuthStore.DEMO_CODE };
  }

  private static requestSettingsCode(phone: string, purpose: MockCodePurpose): SettingsCodeRequestResult {
    MockAuthStore.setChallenge(phone, purpose);
    return { success: true, demoCode: MockAuthStore.DEMO_CODE };
  }

  private static setChallenge(phone: string, purpose: MockCodePurpose): void {
    MockAuthStore.challenges = MockAuthStore.challenges.filter(
      (challenge: MockCodeChallenge) => challenge.purpose !== purpose
    );
    MockAuthStore.challenges.push({
      phone: phone,
      purpose: purpose,
      code: MockAuthStore.DEMO_CODE,
      consumed: false
    });
  }

  private static consumeChallenge(
    phone: string,
    purpose: MockCodePurpose,
    code: string
  ): AccountSettingsErrorCode | undefined {
    const challenge: MockCodeChallenge | undefined = MockAuthStore.challenges.find(
      (item: MockCodeChallenge) => item.purpose === purpose
    );
    if (challenge === undefined) {
      const otherPurpose: boolean = MockAuthStore.challenges.some(
        (item: MockCodeChallenge) => !item.consumed && item.code === code
      );
      return otherPurpose ? 'CODE_PURPOSE_MISMATCH' : 'CODE_NOT_REQUESTED';
    }
    if (challenge.phone !== phone) {
      return 'CODE_PHONE_MISMATCH';
    }
    if (challenge.consumed) {
      return 'CODE_ALREADY_CONSUMED';
    }
    if (challenge.code !== code) {
      return 'INVALID_CODE';
    }
    challenge.consumed = true;
    return undefined;
  }

  private static clearChallenge(purpose: MockCodePurpose): void {
    MockAuthStore.challenges = MockAuthStore.challenges.filter(
      (challenge: MockCodeChallenge) => challenge.purpose !== purpose
    );
  }

  private static clearChallenges(): void {
    MockAuthStore.challenges = [];
  }

  private static authenticate(accountId: string): AuthResult {
    MockAuthStore.currentAccountId = accountId;
    MockAuthStore.clearChallenges();
    MockAuthStore.clearClosureAuthorization();
    return { success: true, session: MockAuthStore.getSession() };
  }

  private static failure(errorCode: AuthErrorCode): AuthResult {
    return { success: false, session: MockAuthStore.getSession(), errorCode: errorCode };
  }

  private static settingsFailure(errorCode: AccountSettingsErrorCode): AccountSettingsResult {
    return { success: false, errorCode: errorCode };
  }

  private static settingsCodeFailure(errorCode: AccountSettingsErrorCode): SettingsCodeRequestResult {
    return { success: false, errorCode: errorCode };
  }

  private static profileAvatarFailure(errorCode: ProfileAvatarUpdateErrorCode): ProfileAvatarUpdateResult {
    return { success: false, errorCode: errorCode };
  }

  private static validateProfileFields(nickname: string, avatarGlyph: string): AccountSettingsErrorCode | undefined {
    if (nickname.length < 1 || nickname.length > 12) {
      return 'INVALID_NICKNAME';
    }
    if (MockAuthStore.AVATAR_GLYPHS.indexOf(avatarGlyph) < 0) {
      return 'INVALID_AVATAR_GLYPH';
    }
    return undefined;
  }

  private static toAuthErrorCode(errorCode: AccountSettingsErrorCode): AuthErrorCode {
    switch (errorCode) {
      case 'CODE_PHONE_MISMATCH':
        return 'CODE_PHONE_MISMATCH';
      case 'CODE_PURPOSE_MISMATCH':
        return 'CODE_PURPOSE_MISMATCH';
      case 'CODE_ALREADY_CONSUMED':
        return 'CODE_ALREADY_CONSUMED';
      case 'INVALID_CODE':
        return 'INVALID_CODE';
      default:
        return 'CODE_NOT_REQUESTED';
    }
  }

  private static currentAccount(): MockAccountRecord | undefined {
    return MockAuthStore.findAccountById(MockAuthStore.currentAccountId);
  }

  private static findAccountById(accountId: string): MockAccountRecord | undefined {
    if (accountId.length === 0) {
      return undefined;
    }
    return MockAuthStore.users.find((account: MockAccountRecord) => account.accountId === accountId);
  }

  private static findAccountByPhone(phone: string): MockAccountRecord | undefined {
    return MockAuthStore.users.find((account: MockAccountRecord) => account.phone === phone);
  }

  private static createAccount(phone: string, password: string | undefined): MockAccountRecord {
    const account: MockAccountRecord = {
      accountId: `MOCK-ACCOUNT-${MockAuthStore.nextAccountNumber}`,
      phone: phone,
      nickname: `用户${phone.substring(7)}`,
      avatarGlyph: '印'
    };
    MockAuthStore.nextAccountNumber += 1;
    if (password !== undefined) {
      account.password = password;
    }
    return account;
  }

  private static projectUser(account: MockAccountRecord): MockUser {
    return {
      userId: account.accountId,
      maskedPhone: MockAuthStore.maskPhone(account.phone),
      nickname: account.nickname,
      avatarGlyph: account.avatarGlyph
    };
  }

  private static maskPhone(phone: string): string {
    return `${phone.substring(0, 3)}****${phone.substring(7)}`;
  }

  private static clearClosureAuthorization(): void {
    MockAuthStore.closureAuthorization = undefined;
  }
}
