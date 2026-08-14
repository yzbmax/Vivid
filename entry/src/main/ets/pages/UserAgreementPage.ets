import { AgreementPage } from '../components/AgreementPage';

const USER_AGREEMENT_SECTIONS: string[] = [
  '欢迎使用蒙版调色。本页面用于展示协议界面的视觉与信息结构，实际服务条款应在应用发布前经审阅后提供。',
  '使用者应通过合法方式使用应用提供的图片编辑界面，并对其导入、编辑和导出的内容负责。',
  '当前版本的登录、注册和设置仅为前端界面示例，不提供真实账号服务或数据持久化能力。'
];

@Entry
@Component
struct UserAgreementPage {
  build() {
    Column() {
      AgreementPage({
        title: '用户协议',
        sections: USER_AGREEMENT_SECTIONS
      });
    }
  }
}
