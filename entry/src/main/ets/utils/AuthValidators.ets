export function validatePhone(phone: string): string {
  return /^1[3-9]\d{9}$/.test(phone) ? '' : '请输入有效的手机号';
}

export function validateCode(code: string): string {
  return /^\d{6}$/.test(code) ? '' : '请输入 6 位验证码';
}

export function validatePassword(password: string): string {
  return /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,20}$/.test(password)
    ? ''
    : '密码需为 8-20 位字母和数字组合';
}

export function validatePasswordConfirmation(password: string, confirmation: string): string {
  return password === confirmation ? '' : '两次输入的密码不一致';
}
