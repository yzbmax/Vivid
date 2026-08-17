import { describe, it, expect } from '@ohos/hypium';
import { MockAuthStore } from '../main/ets/models/MockAuthStore';
import { ProfileAvatarUpdateRequest } from '../main/ets/models/ProfileAvatarModels';

export default function mockAuthStoreTest() {
  describe('mockAuthStoreTest', () => {
    it('declares the profile avatar update request contract', 0, () => {
      const avatarRequest: ProfileAvatarUpdateRequest = {
        nickname: '头像主人',
        avatarGlyph: '印',
        avatarUri: 'file://mock/avatar.jpg'
      };
      expect(avatarRequest.avatarUri).assertEqual('file://mock/avatar.jpg');
    });

    it('binds a demo code to the requested phone', 0, () => {
      MockAuthStore.logout();
      const requested = MockAuthStore.requestCode('13912345678');
      expect(requested.success).assertEqual(true);
      expect(requested.demoCode).assertEqual('123456');

      const switchedPhone = MockAuthStore.loginWithCode('13912345679', '123456');
      expect(switchedPhone.success).assertEqual(false);
      expect(switchedPhone.errorCode).assertEqual('CODE_PHONE_MISMATCH');
    });

    it('logs in with the seeded demo password account', 0, () => {
      MockAuthStore.logout();
      const result = MockAuthStore.loginWithPassword('13800138000', 'Vivid123');
      expect(result.success).assertEqual(true);
      expect(result.session.status).assertEqual('authenticated');
      expect(result.session.user?.maskedPhone).assertEqual('138****8000');
    });

    it('uses one generic error for invalid password credentials', 0, () => {
      MockAuthStore.logout();
      const result = MockAuthStore.loginWithPassword('13800138000', 'Wrong123');
      expect(result.success).assertEqual(false);
      expect(result.errorCode).assertEqual('INVALID_CREDENTIALS');
    });

    it('registers a password account and creates a session', 0, () => {
      MockAuthStore.logout();
      MockAuthStore.requestRegistrationCode('13912345670');
      const result = MockAuthStore.register('13912345670', '123456', 'abc12345');
      expect(result.success).assertEqual(true);
      expect(result.session.status).assertEqual('authenticated');
      expect(MockAuthStore.getCurrentUser()?.maskedPhone).assertEqual('139****5670');
    });

    it('rejects a duplicate registered phone', 0, () => {
      MockAuthStore.logout();
      MockAuthStore.requestRegistrationCode('13912345671');
      const first = MockAuthStore.register('13912345671', '123456', 'abc12345');
      expect(first.success).assertEqual(true);
      MockAuthStore.logout();
      MockAuthStore.requestRegistrationCode('13912345671');
      const duplicate = MockAuthStore.register('13912345671', '123456', 'abc12345');
      expect(duplicate.success).assertEqual(false);
      expect(duplicate.errorCode).assertEqual('PHONE_ALREADY_REGISTERED');
    });

    it('returns an anonymous session after logout', 0, () => {
      MockAuthStore.logout();
      MockAuthStore.loginWithPassword('13800138000', 'Vivid123');
      MockAuthStore.logout();
      expect(MockAuthStore.getSession().status).assertEqual('anonymous');
      expect(MockAuthStore.getCurrentUser()).assertUndefined();
    });

    it('creates a passwordless account with a stable id for code login', 0, () => {
      const phone = '13912345001';
      MockAuthStore.logout();
      MockAuthStore.requestCode(phone);
      const first = MockAuthStore.loginWithCode(phone, '123456');
      expect(first.success).assertEqual(true);
      expect(MockAuthStore.getAccountSecuritySnapshot()?.hasPassword).assertEqual(false);
      const firstId = MockAuthStore.getCurrentUser()?.userId;

      MockAuthStore.logout();
      MockAuthStore.requestCode(phone);
      const second = MockAuthStore.loginWithCode(phone, '123456');
      expect(second.success).assertEqual(true);
      expect(MockAuthStore.getCurrentUser()?.userId).assertEqual(firstId);
    });

    it('does not consume an auth code after a failed code check', 0, () => {
      const phone = '13912345011';
      MockAuthStore.logout();
      MockAuthStore.requestCode(phone);
      expect(MockAuthStore.loginWithCode(phone, '000000').errorCode).assertEqual('INVALID_CODE');
      expect(MockAuthStore.loginWithCode(phone, '123456').success).assertEqual(true);
    });

    it('keeps the current session projection in sync after profile update', 0, () => {
      MockAuthStore.logout();
      MockAuthStore.loginWithPassword('13800138000', 'Vivid123');
      const result = MockAuthStore.updateProfile({ nickname: '册页主人', avatarGlyph: '墨' });
      expect(result.success).assertEqual(true);
      expect(MockAuthStore.getCurrentUser()?.nickname).assertEqual('册页主人');
      expect(MockAuthStore.getCurrentUser()?.avatarGlyph).assertEqual('墨');
    });

    it('rejects blank, oversized and unknown profile values', 0, () => {
      MockAuthStore.loginWithPassword('13800138000', 'Vivid123');
      expect(MockAuthStore.updateProfile({ nickname: '   ', avatarGlyph: '印' }).errorCode)
        .assertEqual('INVALID_NICKNAME');
      expect(MockAuthStore.updateProfile({ nickname: '1234567890123', avatarGlyph: '印' }).errorCode)
        .assertEqual('INVALID_NICKNAME');
      expect(MockAuthStore.updateProfile({ nickname: '有效称谓', avatarGlyph: '无' }).errorCode)
        .assertEqual('INVALID_AVATAR_GLYPH');
    });

    it('saves and reloads a profile avatar URI without changing the public user contract', 0, () => {
      MockAuthStore.logout();
      MockAuthStore.loginWithPassword('13800138000', 'Vivid123');
      const saved = MockAuthStore.updateProfileWithAvatar({
        nickname: '头像主人', avatarGlyph: '墨', avatarUri: 'file://mock/avatar.jpg'
      });
      expect(saved.success).assertEqual(true);
      expect(MockAuthStore.getCurrentAvatarUri()).assertEqual('file://mock/avatar.jpg');
      expect(MockAuthStore.getCurrentUser()?.nickname).assertEqual('头像主人');
      expect(MockAuthStore.getCurrentUser()?.avatarGlyph).assertEqual('墨');
      expect(MockAuthStore.getSession().user?.userId).assertEqual('MOCK-ACCOUNT-1');

      MockAuthStore.logout();
      MockAuthStore.loginWithPassword('13800138000', 'Vivid123');
      expect(MockAuthStore.getCurrentAvatarUri()).assertEqual('file://mock/avatar.jpg');
    });

    it('rejects an empty avatar URI without partially updating the profile', 0, () => {
      MockAuthStore.logout();
      MockAuthStore.loginWithPassword('13800138000', 'Vivid123');
      const before = MockAuthStore.getCurrentUser();
      const result = MockAuthStore.updateProfileWithAvatar({
        nickname: '不应保存', avatarGlyph: '朱', avatarUri: '   '
      });
      expect(result.success).assertEqual(false);
      expect(result.errorCode).assertEqual('INVALID_AVATAR_URI');
      expect(MockAuthStore.getCurrentUser()?.nickname).assertEqual(before?.nickname);
      expect(MockAuthStore.getCurrentUser()?.avatarGlyph).assertEqual(before?.avatarGlyph);
      expect(MockAuthStore.getCurrentAvatarUri()).assertEqual('file://mock/avatar.jpg');
    });

    it('rejects avatar updates while anonymous', 0, () => {
      MockAuthStore.logout();
      const result = MockAuthStore.updateProfileWithAvatar({
        nickname: '匿名用户', avatarGlyph: '印', avatarUri: 'file://mock/anonymous.jpg'
      });
      expect(result.success).assertEqual(false);
      expect(result.errorCode).assertEqual('NOT_AUTHENTICATED');
      expect(MockAuthStore.getCurrentAvatarUri()).assertUndefined();
    });

    it('preserves an avatar through logout and removes it with account closure', 0, () => {
      const phone = '13912345017';
      MockAuthStore.logout();
      MockAuthStore.requestCode(phone);
      MockAuthStore.loginWithCode(phone, '123456');
      const user = MockAuthStore.getCurrentUser();
      MockAuthStore.updateProfileWithAvatar({
        nickname: user?.nickname ?? '头像主人', avatarGlyph: user?.avatarGlyph ?? '印',
        avatarUri: 'file://mock/temporary-avatar.jpg'
      });
      MockAuthStore.logout();
      MockAuthStore.requestCode(phone);
      MockAuthStore.loginWithCode(phone, '123456');
      expect(MockAuthStore.getCurrentAvatarUri()).assertEqual('file://mock/temporary-avatar.jpg');

      MockAuthStore.requestAccountClosureCode();
      MockAuthStore.verifyAccountClosure({ method: 'code', credential: '123456' });
      expect(MockAuthStore.closeAccount().success).assertEqual(true);
      expect(MockAuthStore.getCurrentAvatarUri()).assertUndefined();
    });

    it('keeps account id stable when binding a new phone', 0, () => {
      const oldPhone = '13912345002';
      const newPhone = '13912345003';
      MockAuthStore.logout();
      MockAuthStore.requestCode(oldPhone);
      MockAuthStore.loginWithCode(oldPhone, '123456');
      const accountId = MockAuthStore.getCurrentUser()?.userId;

      MockAuthStore.requestPhoneBindingCode(newPhone);
      const result = MockAuthStore.changePhoneBinding({ newPhone: newPhone, code: '123456' });
      expect(result.success).assertEqual(true);
      expect(MockAuthStore.getCurrentUser()?.userId).assertEqual(accountId);
      expect(MockAuthStore.getCurrentUser()?.maskedPhone).assertEqual('139****5003');
    });

    it('rejects a phone already bound to another account', 0, () => {
      const firstPhone = '13912345012';
      const secondPhone = '13912345013';
      MockAuthStore.logout();
      MockAuthStore.requestRegistrationCode(firstPhone);
      MockAuthStore.register(firstPhone, '123456', 'abc12345');
      MockAuthStore.logout();
      MockAuthStore.requestRegistrationCode(secondPhone);
      MockAuthStore.register(secondPhone, '123456', 'abc12345');
      const result = MockAuthStore.requestPhoneBindingCode(firstPhone);
      expect(result.success).assertEqual(false);
      expect(result.errorCode).assertEqual('PHONE_ALREADY_BOUND');
    });

    it('rejects a password setup code issued for the previous phone', 0, () => {
      const oldPhone = '13912345004';
      const newPhone = '13912345005';
      MockAuthStore.logout();
      MockAuthStore.requestCode(oldPhone);
      MockAuthStore.loginWithCode(oldPhone, '123456');
      MockAuthStore.requestPasswordSetupCode();
      MockAuthStore.requestPhoneBindingCode(newPhone);
      MockAuthStore.changePhoneBinding({ newPhone: newPhone, code: '123456' });

      const result = MockAuthStore.setupPassword({ code: '123456', newPassword: 'abc12345' });
      expect(result.success).assertEqual(false);
      expect(result.errorCode).assertEqual('CODE_PHONE_MISMATCH');
    });

    it('consumes a password setup code exactly once', 0, () => {
      const phone = '13912345006';
      MockAuthStore.logout();
      MockAuthStore.requestCode(phone);
      MockAuthStore.loginWithCode(phone, '123456');
      MockAuthStore.requestPasswordSetupCode();
      const first = MockAuthStore.setupPassword({ code: '123456', newPassword: 'abc12345' });
      expect(first.success).assertEqual(true);
      const second = MockAuthStore.setupPassword({ code: '123456', newPassword: 'def12345' });
      expect(second.success).assertEqual(false);
      expect(second.errorCode).assertEqual('PASSWORD_ALREADY_SET');
    });

    it('requires the current password and rejects the same password', 0, () => {
      const phone = '13912345009';
      MockAuthStore.logout();
      MockAuthStore.requestRegistrationCode(phone);
      MockAuthStore.register(phone, '123456', 'Vivid123');
      const wrong = MockAuthStore.changePassword({ currentPassword: 'Wrong123', newPassword: 'abc12345' });
      expect(wrong.errorCode).assertEqual('INCORRECT_CURRENT_PASSWORD');
      const same = MockAuthStore.changePassword({ currentPassword: 'Vivid123', newPassword: 'Vivid123' });
      expect(same.errorCode).assertEqual('SAME_PASSWORD');
      const changed = MockAuthStore.changePassword({ currentPassword: 'Vivid123', newPassword: 'abc12345' });
      expect(changed.success).assertEqual(true);
    });

    it('does not allow a phone binding challenge to close an account', 0, () => {
      MockAuthStore.logout();
      MockAuthStore.loginWithPassword('13912345009', 'abc12345');
      MockAuthStore.requestPhoneBindingCode('13912345010');
      const result = MockAuthStore.verifyAccountClosure({ method: 'code', credential: '123456' });
      expect(result.success).assertEqual(false);
      expect(result.errorCode).assertEqual('CODE_PURPOSE_MISMATCH');
    });

    it('clears closure authorization on cancel and logout', 0, () => {
      MockAuthStore.logout();
      const login = MockAuthStore.loginWithPassword('13800138000', 'Vivid123');
      expect(login.success).assertEqual(true);
      const verified = MockAuthStore.verifyAccountClosure({ method: 'password', credential: 'abc12345' });
      expect(verified.success).assertEqual(false);
      expect(verified.errorCode).assertEqual('INVALID_CREDENTIALS');
      const validVerification = MockAuthStore.verifyAccountClosure({ method: 'password', credential: 'Vivid123' });
      expect(validVerification.success).assertEqual(true);
      MockAuthStore.cancelAccountClosure();
      expect(MockAuthStore.closeAccount().errorCode).assertEqual('CLOSURE_NOT_VERIFIED');

      const secondVerification = MockAuthStore.verifyAccountClosure({ method: 'password', credential: 'Vivid123' });
      expect(secondVerification.success).assertEqual(true);
      MockAuthStore.logout();
      expect(MockAuthStore.closeAccount().errorCode).assertEqual('CLOSURE_NOT_VERIFIED');
    });

    it('clears closure authorization when the current account changes', 0, () => {
      const firstPhone = '13912345014';
      const secondPhone = '13912345015';
      MockAuthStore.logout();
      MockAuthStore.requestRegistrationCode(firstPhone);
      MockAuthStore.register(firstPhone, '123456', 'abc12345');
      MockAuthStore.logout();
      MockAuthStore.requestRegistrationCode(secondPhone);
      MockAuthStore.register(secondPhone, '123456', 'abc12345');
      MockAuthStore.loginWithPassword(firstPhone, 'abc12345');
      MockAuthStore.verifyAccountClosure({ method: 'password', credential: 'abc12345' });
      MockAuthStore.loginWithPassword(secondPhone, 'abc12345');
      expect(MockAuthStore.closeAccount().errorCode).assertEqual('CLOSURE_NOT_VERIFIED');
    });

    it('can close a passwordless account with its current phone code', 0, () => {
      const phone = '13912345016';
      MockAuthStore.logout();
      MockAuthStore.requestCode(phone);
      MockAuthStore.loginWithCode(phone, '123456');
      MockAuthStore.requestAccountClosureCode();
      const verified = MockAuthStore.verifyAccountClosure({ method: 'code', credential: '123456' });
      expect(verified.success).assertEqual(true);
      const reused = MockAuthStore.verifyAccountClosure({ method: 'code', credential: '123456' });
      expect(reused.errorCode).assertEqual('CODE_ALREADY_CONSUMED');
      MockAuthStore.requestAccountClosureCode();
      MockAuthStore.verifyAccountClosure({ method: 'code', credential: '123456' });
      expect(MockAuthStore.closeAccount().success).assertEqual(true);
      expect(MockAuthStore.getSession().status).assertEqual('anonymous');
    });

    it('deletes only the verified account and clears session', 0, () => {
      const phone = '13912345008';
      MockAuthStore.requestRegistrationCode(phone);
      MockAuthStore.register(phone, '123456', 'abc12345');
      const verified = MockAuthStore.verifyAccountClosure({ method: 'password', credential: 'abc12345' });
      expect(verified.success).assertEqual(true);
      const closed = MockAuthStore.closeAccount();
      expect(closed.success).assertEqual(true);
      expect(MockAuthStore.getSession().status).assertEqual('anonymous');
      expect(MockAuthStore.closeAccount().errorCode).assertEqual('CLOSURE_NOT_VERIFIED');
    });
  });
}
