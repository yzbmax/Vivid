import { Theme } from './Theme';

/** 数字转中文大写（支持 0~9999） */
function toUpperChinese(num: number): string {
  const digits: string[] = ['零', '壹', '贰', '叁', '肆', '伍', '陆', '柒', '捌', '玖'];
  const units: string[] = ['', '拾', '佰', '仟'];
  if (num === 0) {
    return '零';
  }
  let result: string = '';
  let unitIndex: number = 0;
  let needZero: boolean = false;
  while (num > 0) {
    const digit: number = num % 10;
    if (digit === 0) {
      needZero = true;
    } else {
      if (needZero && result !== '') {
        result = '零' + result;
      }
      result = digits[digit] + units[unitIndex] + result;
      needZero = false;
    }
    num = Math.floor(num / 10);
    unitIndex++;
  }
  return result;
}

/**
 * 卷宗落款信息条：底导航上方居中一条 pill，展示已汇集的作品总数（中文大写）。
 * 参考：docs/公共组件预留文档.md A4。
 */
@Component
export struct FooterSealBar {
  /** 作品总数 */
  count: number = 0;

  build() {
    Row() {
      Text(`汇集诸作·总计${toUpperChinese(this.count)}卷`)
        .fontFamily(Theme.FONT_MONO)
        .fontSize(Theme.FONT_SIZE_LABEL_MONO)
        .fontWeight(500)
        .fontColor(Theme.PRIMARY_60)
        .letterSpacing(1.3)
    }
    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
    .border({ width: 1, color: Theme.PRIMARY_20 })
    // .backgroundColor(Theme.PRIMARY_05)
  }
}
