import { Theme } from '../common/Theme';
import { EmptyState } from '../common/EmptyState';
import { WorkCard } from './WorkCard';
import { WorkRecord } from '../../models/WorkRecord';

/**
 * 作品 2 列瀑布流：自适应照片原本画幅，左右双列高度智能平衡分流，
 * 杜绝任何画面裁切与空隙挤压，与外层 Scroll 完美融为一体。
 */
@Component
export struct WorkGrid {
  @Prop @Watch('onItemsChange') items: WorkRecord[] = [];
  emptyTitle: string = '暂无作品';
  emptyDescription: string = '导入图片开始创作';
  onCardClick: (id: string) => void = () => {};
  onCardLongPress: (id: string) => void = () => {};

  @State private leftColumnWorks: WorkRecord[] = [];
  @State private rightColumnWorks: WorkRecord[] = [];

  aboutToAppear(): void {
    this.splitColumns();
  }

  private onItemsChange(): void {
    this.splitColumns();
  }

  /**
   * 单次遍历按预估高度动态贪心平衡左右两列
   */
  private splitColumns(): void {
    const left: WorkRecord[] = [];
    const right: WorkRecord[] = [];
    let leftH = 0;
    let rightH = 0;

    for (let i = 0; i < this.items.length; i++) {
      const item = this.items[i];
      const ratio = (item.width > 0 && item.height > 0) ? (item.height / item.width) : 1.0;
      const estH = Math.round(170 * Math.max(0.5, Math.min(2.0, ratio))) + 68;

      if (leftH <= rightH) {
        left.push(item);
        leftH += estH;
      } else {
        right.push(item);
        rightH += estH;
      }
    }
    this.leftColumnWorks = left;
    this.rightColumnWorks = right;
  }

  build() {
    if (this.items.length === 0) {
      EmptyState({
        title: this.emptyTitle,
        description: this.emptyDescription,
        actionText: '前往首页',
        onAction: () => {
          AppStorage.setOrCreate('mainTabIndex', 0);
        }
      })
    } else {
      Row({ space: Theme.GUTTER }) {
        // 左列（高度均衡双列瀑布流）
        Column({ space: Theme.GUTTER }) {
          ForEach(this.leftColumnWorks, (item: WorkRecord) => {
            WorkCard({
              data: item,
              onCardClick: (id: string) => this.onCardClick(id),
              onCardLongPress: (id: string) => this.onCardLongPress(id)
            })
              .width('100%')
          }, (item: WorkRecord) => item.id)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 右列
        Column({ space: Theme.GUTTER }) {
          ForEach(this.rightColumnWorks, (item: WorkRecord) => {
            WorkCard({
              data: item,
              onCardClick: (id: string) => this.onCardClick(id),
              onCardLongPress: (id: string) => this.onCardLongPress(id)
            })
              .width('100%')
          }, (item: WorkRecord) => item.id)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
    }
  }
}
