import { Theme } from '../components/common/Theme';
import { PaperBackground } from '../components/common/PaperBackground';
import { SegmentTabs, SegmentItem } from '../components/common/SegmentTabs';
import { FooterSealBar } from '../components/common/FooterSealBar';
import { WorkGrid } from '../components/works/WorkGrid';
import { WorkRecord, WorkStatus } from '../models/WorkRecord';
import { buildMockWorks } from '../models/MockWorks';

/**
 * 作品页（WorksPage，PRD F10 / §7.3，stitch_「Works Page」档存样板）。
 *
 * 职责：展示已保存作品、支持「全部卷宗 / 已封印 / 草稿」筛选与点击继续编辑。
 * 本次实现范围：仅前端展示，作品数据为 mock；底部不实现主导航，仅预留 MainTabBar 占位空间。
 * 后续接入：WorksStore + WorkRepository 提供真实列表；点击作品经 EditEntryMode 打开独立编辑页。
 */
@Entry
@Component
export struct WorksPage {
    @State works: WorkRecord[] = [];
    @State selectedFilter: string = 'all';
    /** 排序：true=按保存时间倒序（默认），false=正序 */
    @State sortDescending: boolean = true;

    private filterItems: SegmentItem[] = [
        { label: '全部卷宗 (ALL)', key: 'all' },
        { label: '已封印 (SEALED)', key: 'sealed' },
        { label: '草稿 (DRAFTS)', key: 'draft' }
    ];

    aboutToAppear(): void {
        this.works = buildMockWorks();
    }

    build() {
        // @Entry 根节点必须是内置容器组件，故以 Column 作为外层，宣纸背景作为子层铺满
        Column() {
            PaperBackground() {
                Column() {
                    // 顶部栏（TopBar）暂未启用
                    Scroll() {
                        Column() {
                            // 筛选分段（Works Page 样板：全部卷宗 / 已封印 / 草稿）
                            SegmentTabs({
                                items: this.filterItems,
                                selected: this.selectedFilter,
                                cornerMark: true,
                                chipMode: true,
                                onChange: (key: string) => {
                                    this.selectedFilter = key;
                                }
                            })
                            this.statBlock()
                            WorkGrid({
                                items: this.displayedWorks(),
                                onCardClick: (id: string) => {
                                    this.onWorkClick(id);
                                }
                            })
                            this.endMark()
                        }
                        .width('100%')
                        .padding({ bottom: 24 })
                    }
                    .layoutWeight(1)
                    .scrollBar(BarState.Off)
                    .edgeEffect(EdgeEffect.Spring)
                    // 底部：卷宗落款 + 底部主导航占位
                    Column() {
                        Column() {
                            FooterSealBar({ number: '肆零玖' })
                        }
                        .width('100%')
                        .padding({ top: 8, bottom: 8 })
                        // 预留底部主导航（MainTabBar）高度，避免后续布局冲突
                        Row()
                            .width('100%')
                            .height(Theme.NAV_BAR_HEIGHT)
                            .opacity(0)
                    }
                    .width('100%')
                    .backgroundColor(Theme.PAPER_BASE_90)
                    .backdropBlur(24)
                }
                .width('100%')
                .height('100%')
            }
        }
        .width('100%')
        .height('100%')
    }

    /** 统计区：大数字 + 等宽标签 + 排序钮（排序钮归页面级） */
    @Builder
    statBlock() {
        Row() {
            Column() {
                Text('叁拾贰')
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(Theme.FONT_SIZE_HEADLINE_LG_MOBILE)
                    .fontWeight(700)
                    .fontColor(Theme.ON_SURFACE)
                    .letterSpacing(0.7)
                Text('TOTAL ARCHIVED WORKS')
                    .fontFamily(Theme.FONT_MONO)
                    .fontSize(Theme.FONT_SIZE_LABEL_MONO)
                    .fontWeight(500)
                    .fontColor(Theme.ON_SURFACE_VARIANT)
                    .letterSpacing(1.3)
                    .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            Blank()
            Stack({ alignContent: Alignment.Center }) {
                Image($r('app.media.icon_sort'))
                    .width(18)
                    .height(18)
                    .fillColor(Theme.PRIMARY)
                    .rotate({ angle: this.sortDescending ? 0 : 180 })
                    .animation({ duration: 200, curve: Curve.EaseOut })
            }
            .width(32)
            .height(32)
            .backgroundColor(Theme.SURFACE_CONTAINER)
            .shadow({ radius: 2, color: Theme.SHADOW_SM, offsetY: 1 })
            .stateStyles({ pressed: this.statPressed })
            .onClick(() => {
                this.onSortToggle();
            })
        }
        .width('100%')
        .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, bottom: 24 })
        .alignItems(VerticalAlign.Bottom)
    }

    /** 结束装饰：短线 · 斜方 · 短线 */
    @Builder
    endMark() {
        Row() {
            Row()
                .width(48)
                .height(1)
                .backgroundColor(Theme.OUTLINE)
            Row()
                .width(12)
                .height(12)
                .backgroundColor(Theme.PRIMARY)
                .rotate({ angle: 45 })
                .margin({ left: 12, right: 12 })
            Row()
                .width(48)
                .height(1)
                .backgroundColor(Theme.OUTLINE)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .opacity(0.4)
        .padding({ top: 16, bottom: 16 })
    }

    @Styles
    statPressed() {
        .scale({ x: 0.94, y: 0.94 })
    }

    /** 排序切换：倒序/正序切换并提示 */
    private onSortToggle(): void {
        this.sortDescending = !this.sortDescending;
        try {
            this.getUIContext().getPromptAction().showToast({
                message: this.sortDescending ? '按保存时间倒序' : '按保存时间正序'
            });
        } catch (e) {
            // 提示失败不影响排序
        }
    }

    /** 当前筛选 + 排序后的作品列表 */
    private displayedWorks(): WorkRecord[] {
        let result: WorkRecord[] = this.works;
        if (this.selectedFilter === 'sealed') {
            result = this.works.filter((w: WorkRecord) => w.status === WorkStatus.Sealed);
        } else if (this.selectedFilter === 'draft') {
            result = this.works.filter((w: WorkRecord) => w.status === WorkStatus.Draft);
        }
        const sorted: WorkRecord[] = result.slice();
        sorted.sort((a: WorkRecord, b: WorkRecord) =>
        this.sortDescending ? b.updatedAt - a.updatedAt : a.updatedAt - b.updatedAt);
        return sorted;
    }

    /** 点击作品：打开作品详情页（WorkDetailPage，携带 workId） */
    private onWorkClick(id: string): void {
        // TODO: 接入 WorkRepository 恢复源图/蒙版/参数后，由详情页「启封续编」进入 EditPage 继续编辑
        this.getUIContext().getRouter().pushUrl({ url: 'pages/WorkDetailPage', params: { workId: id } }).catch(() => {
            // 路由失败不影响列表
        });
    }
}
