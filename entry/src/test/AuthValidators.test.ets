import { describe, it, expect } from '@ohos/hypium';
import {
  validateCode,
  validatePassword,
  validatePasswordConfirmation,
  validatePhone
} from '../main/ets/utils/AuthValidators';

export default function authValidatorsTest() {
  describe('authValidatorsTest', () => {
    it('accepts a valid mainland phone number', 0, () => {
      expect(validatePhone('13812345678')).assertEqual('');
    });

    it('rejects malformed phone numbers', 0, () => {
      expect(validatePhone('12812345678')).assertEqual('请输入有效的手机号');
      expect(validatePhone('1381234567a')).assertEqual('请输入有效的手机号');
      expect(validatePhone('1381234567')).assertEqual('请输入有效的手机号');
    });

    it('accepts a six digit verification code', 0, () => {
      expect(validateCode('123456')).assertEqual('');
    });

    it('rejects malformed verification codes', 0, () => {
      expect(validateCode('12345')).assertEqual('请输入 6 位验证码');
      expect(validateCode('12345a')).assertEqual('请输入 6 位验证码');
    });

    it('accepts alphanumeric passwords from eight to twenty characters', 0, () => {
      expect(validatePassword('abc12345')).assertEqual('');
      expect(validatePassword('ABC12345')).assertEqual('');
    });

    it('rejects passwords without letters numbers or valid characters', 0, () => {
      expect(validatePassword('abcdefgh')).assertEqual('密码需为 8-20 位字母和数字组合');
      expect(validatePassword('12345678')).assertEqual('密码需为 8-20 位字母和数字组合');
      expect(validatePassword('abc123_45')).assertEqual('密码需为 8-20 位字母和数字组合');
      expect(validatePassword('abc1234')).assertEqual('密码需为 8-20 位字母和数字组合');
      expect(validatePassword('abc123456789012345678')).assertEqual('密码需为 8-20 位字母和数字组合');
    });

    it('requires matching password confirmation', 0, () => {
      expect(validatePasswordConfirmation('abc12345', 'abc12345')).assertEqual('');
      expect(validatePasswordConfirmation('abc12345', 'abc12346')).assertEqual('两次输入的密码不一致');
    });
  });
}
