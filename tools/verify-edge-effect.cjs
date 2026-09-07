/**
 * 自动化边界滑动反馈动效（EdgeEffect.Spring）校验测试
 * 
 * 校验要求：
 * - 页面/面板上下滑动到顶部或底部时，具有弹性反馈动效 (.edgeEffect(EdgeEffect.Spring...))
 * - 横向列表/分段器/选择栏左右滑动到左或右边界时，具有弹性反馈动效 (.edgeEffect(EdgeEffect.Spring...))
 */
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');

const TARGETS = [
  // 1. 页面级垂直滚动容器
  {
    file: 'entry/src/main/ets/components/home/HomePage.ets',
    desc: '首页外层纵向主滚动容器 Scroll'
  },
  {
    file: 'entry/src/main/ets/pages/WorksPage.ets',
    desc: '卷宗归档页纵向滚动容器 Scroll'
  },
  {
    file: 'entry/src/main/ets/pages/WorkDetailPage.ets',
    desc: '卷宗详情页纵向滚动容器 Scroll'
  },
  {
    file: 'entry/src/main/ets/components/mine/MinePage.ets',
    desc: '「我的」个人中心纵向滚动容器 Scroll'
  },
  {
    file: 'entry/src/main/ets/pages/UserSettingsPage.ets',
    desc: '用户资料页纵向滚动容器 Scroll'
  },
  {
    file: 'entry/src/main/ets/pages/ProfileEditPage.ets',
    desc: '个人信息编辑页纵向滚动容器 Scroll'
  },
  {
    file: 'entry/src/main/ets/pages/AccountSecurityPage.ets',
    desc: '账号安全设置页纵向滚动容器 Scroll'
  },
  {
    file: 'entry/src/main/ets/pages/AppSettingsPage.ets',
    desc: '应用偏好设置页纵向滚动容器 Scroll'
  },
  {
    file: 'entry/src/main/ets/pages/LoginPage.ets',
    desc: '登录页面纵向滚动容器 Scroll'
  },
  {
    file: 'entry/src/main/ets/pages/RegisterPage.ets',
    desc: '注册页面纵向滚动容器 Scroll'
  },
  {
    file: 'entry/src/main/ets/components/AgreementPage.ets',
    desc: '用户协议与隐私政策纵向滚动容器 Scroll'
  },
  {
    file: 'entry/src/main/ets/pages/SubjectSegDebugPage.ets',
    desc: '抠图调试页纵向滚动容器 Scroll'
  },

  // 2. 编辑面板与模态弹窗滚动容器
  {
    file: 'entry/src/main/ets/components/editor/BorderTemplatePickerModal.ets',
    desc: '边框模板弹窗纵向网格 Grid 与水平分类栏 Scroll'
  },
  {
    file: 'entry/src/main/ets/components/editor/BorderPanel.ets',
    desc: '边框面板横向选择条与参数微调纵向 Scroll'
  },
  {
    file: 'entry/src/main/ets/components/editor/TextPanel.ets',
    desc: '文字排版编辑面板纵向 Scroll'
  },
  {
    file: 'entry/src/main/ets/components/editor/FilterPanel.ets',
    desc: '滤镜面板横向胶卷选择栏 Scroll'
  },
  {
    file: 'entry/src/main/ets/components/editor/StickerPanel.ets',
    desc: '贴纸面板横向选择栏 Scroll'
  },

  // 3. 横向滚动列表与分段栏
  {
    file: 'entry/src/main/ets/components/home/RecentWorkSection.ets',
    desc: '案头近辑横向滚动画廊 List'
  },
  {
    file: 'entry/src/main/ets/components/home/QuickToolsSection.ets',
    desc: '格物八法横向快捷工具栏 List'
  },
  {
    file: 'entry/src/main/ets/components/common/SegmentTabs.ets',
    desc: '通用分段标签横向滚动条 Scroll'
  }
];

let passed = 0;
let failed = 0;

console.log('====================================================');
console.log('滑动边界反馈动效（EdgeEffect.Spring）覆盖率校验');
console.log('====================================================');

for (const target of TARGETS) {
  const fullPath = path.resolve(root, target.file);
  if (!fs.existsSync(fullPath)) {
    console.error(`  [FAIL] 文件不存在: ${target.file}`);
    failed++;
    continue;
  }

  const content = fs.readFileSync(fullPath, 'utf8');
  // 检查是否包含 edgeEffect(EdgeEffect.Spring
  const hasEdgeEffect = content.includes('edgeEffect(EdgeEffect.Spring') || content.includes('.edgeEffect(EdgeEffect.Spring');

  if (hasEdgeEffect) {
    console.log(`  [PASS] ${target.file}: ${target.desc}`);
    passed++;
  } else {
    console.error(`  [FAIL] ${target.file} 缺少 EdgeEffect.Spring 边界反馈动效 (${target.desc})`);
    failed++;
  }
}

console.log('\n====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项未配置`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
} else {
  console.log('🎉 所有滑动容器均已配置边界反馈动效！');
}
