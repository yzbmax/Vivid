import { AgreementPage } from '../components/AgreementPage';

const PRIVACY_POLICY_SECTIONS: string[] = [
  '本页面为隐私政策界面示例，正式发布前应根据实际数据处理方式提供经审阅的完整政策。',
  '当前前端演示不会创建真实账号，不会发送验证码，也不会将输入的手机号、验证码、密码或设置写入持久化存储。',
  '若后续接入图片编辑、作品保存或账号服务，应在功能上线前更新隐私政策并明确告知数据用途、保存期限与用户权利。'
];

@Entry
@Component
struct PrivacyPolicyPage {
  build() {
    Column() {
      AgreementPage({
        title: '隐私政策',
        sections: PRIVACY_POLICY_SECTIONS
      });
    }
  }
}
