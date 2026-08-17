import { describe, it, expect } from '@ohos/hypium';
import { MockAuthStore } from '../main/ets/models/MockAuthStore';

export default function mockAuthStoreTest() {
  describe('mockAuthStoreTest', () => {
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
      MockAuthStore.requestCode('13912345670');
      const result = MockAuthStore.register('13912345670', '123456', 'abc12345');
      expect(result.success).assertEqual(true);
      expect(result.session.status).assertEqual('authenticated');
      expect(MockAuthStore.getCurrentUser()?.maskedPhone).assertEqual('139****5670');
    });

    it('rejects a duplicate registered phone', 0, () => {
      MockAuthStore.logout();
      MockAuthStore.requestCode('13912345671');
      const first = MockAuthStore.register('13912345671', '123456', 'abc12345');
      expect(first.success).assertEqual(true);
      MockAuthStore.logout();
      MockAuthStore.requestCode('13912345671');
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
  });
}
