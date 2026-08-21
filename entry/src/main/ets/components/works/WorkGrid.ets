import { Theme } from '../common/Theme';
import { EmptyState } from '../common/EmptyState';
import { WorkCard } from './WorkCard';
import { WorkRecord } from '../../models/WorkRecord';

/**
 * 作品 2 列网格：每行固定两卡（layoutWeight 均分，奇数末行左侧对齐），
 * 空数据时展示 EmptyState。参考：docs/公共组件预留文档.md C6。
 */
@Component
export struct WorkGrid {
  @Prop items: WorkRecord[] = [];
  emptyTitle: string = '暂无作品';
  emptyDescription: string = '导入图片开始创作';
  onCardClick: (id: string) => void = () => {};
  onCardLongPress: (id: string) => void = () => {};

  build() {
    if (this.items.length === 0) {
      EmptyState({ title: this.emptyTitle, description: this.emptyDescription })
    } else {
      Column() {
        ForEach(this.buildRows(), (row: WorkRecord[], index: number) => {
          Row({ space: Theme.GUTTER }) {
            ForEach(row, (item: WorkRecord) => {
              WorkCard({
                data: item,
                onCardClick: (id: string) => this.onCardClick(id),
                onCardLongPress: (id: string) => this.onCardLongPress(id)
              })
                .layoutWeight(1)
            }, (item: WorkRecord) => item.id)
            if (row.length === 1) {
              Row()
                .layoutWeight(1)
            }
          }
          .width('100%')
          .margin({ bottom: Theme.GUTTER })
        }, (row: WorkRecord[], index: number) => row[0].id + '-' + index)
      }
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
    }
  }

  private buildRows(): WorkRecord[][] {
    const rows: WorkRecord[][] = [];
    for (let i = 0; i < this.items.length; i += 2) {
      rows.push(this.items.slice(i, i + 2));
    }
    return rows;
  }
}
