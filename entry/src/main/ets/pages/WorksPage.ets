import { Theme } from '../components/common/Theme';
import { PaperBackground } from '../components/common/PaperBackground';
import { PageHeader } from '../components/common/PageHeader';
import { SegmentTabs, SegmentItem } from '../components/common/SegmentTabs';
import { FooterSealBar } from '../components/common/FooterSealBar';
import { WorkGrid } from '../components/works/WorkGrid';
import { WorkRecord, WorkStatus } from '../models/WorkRecord';
import { mockWorkStore } from '../models/MockWorkStore';
import { EditEntrySource } from '../models/EditModels';
import { WorkUiState } from '../models/WorkUiState';
import { WorkSaveService } from '../services/WorkSaveService';
import { PhotoExportService } from '../services/PhotoExportService';
import { common } from '@kit.AbilityKit';

/**
 * 作品页（WorksPage，PRD F10 / §7.3，stitch_「Works Page」档存样板）。
 *
 * 职责：展示已保存作品、支持「全部卷宗 / 已封印 / 草稿」筛选与点击继续编辑。
 * 本次实现范围：仅前端展示，作品数据为 mock；底部不实现主导航，仅预留 MainTabBar 占位空间。
 * 后续接入：WorksStore + WorkRepository 提供真实列表；点击作品经 EditEntryMode 打开独立编辑页。
 */

@Component
export struct WorksPage {
    @State works: WorkRecord[] = [];
    @State selectedFilter: string = 'all';
    /** 排序：true=按保存时间倒序（默认），false=正序 */
    @State sortDescending: boolean = true;
    /** 当前正在导出的作品 ID */
    @State exportingWorkId: string = '';

    private filterItems: SegmentItem[] = [
        { label: '全部卷宗 (ALL)', key: 'all' },
        { label: '已封印 (SEALED)', key: 'sealed' },
        { label: '草稿 (DRAFTS)', key: 'draft' }
    ];

    private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    private unsubWorkUi: (() => void) | null = null;

    aboutToAppear(): void {
        mockWorkStore.init();
        this.works = mockWorkStore.list();
        this.unsubWorkUi = WorkUiState.onChange(() => {
            this.works = mockWorkStore.list();
        });
    }

    aboutToDisappear(): void {
        if (this.unsubWorkUi !== null) {
            this.unsubWorkUi();
            this.unsubWorkUi = null;
        }
    }

    build() {
        // @Entry 根节点必须是内置容器组件，故以 Column 作为外层，宣纸背景作为子层铺满
        Column() {
            PaperBackground() {
                Column() {
                    // 统一头部标题栏（自顶避让状态栏，背景延伸至屏幕顶部）
                    PageHeader({ title: '作品', showBack: false, onBack: () => {}, topInset: true })
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
                                emptyTitle: '暂无作品',
                                emptyDescription: '导入图片开始创作',
                                onCardClick: (id: string) => {
                                    this.onWorkClick(id);
                                },
                                onCardLongPress: (id: string) => {
                                    this.onWorkLongPress(id);
                                }
                            })
                            this.endMark()
                        }
                        .width('100%')
                        .constraintSize({ minHeight: '100%' })
                        .padding({ bottom: 24 })
                    }
                    .layoutWeight(1)
                    .scrollBar(BarState.Off)
                    .edgeEffect(EdgeEffect.Spring)
                    // 底部：卷宗落款（底部导航由 Index 的 Tabs 提供，本页不再预留占位）
                    Column() {
                        Column() {
                            FooterSealBar({ count: this.works.length })
                        }
                        .width('100%')
                        .padding({ top: 8, bottom: 8 })
                        // .backgroundImageSize({ width: '', height: '' })
                    }
                    .width('100%')
                    // 透明背景 + 无模糊，让下方网格纹理透出
                    // .backgroundColor(Theme.PAPER_BASE_90)
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
                Text(this.works.length.toString())
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

    /** 点击作品：草稿直接进入编辑页续编；已封缄进入详情页。 */
    private onWorkClick(id: string): void {
        const work = mockWorkStore.findById(id);
        if (work != null && work.status === WorkStatus.Draft) {
            this.getUIContext().getRouter().pushUrl({
                url: 'pages/EditPage',
                params: { source: EditEntrySource.Work, workId: id }
            }).catch(() => {
                // 路由失败不影响列表
            });
            return;
        }
        this.getUIContext().getRouter().pushUrl({ url: 'pages/WorkDetailPage', params: { workId: id } }).catch(() => {
            // 路由失败不影响列表
        });
    }

    /** 长按作品：显示操作菜单（含导出选项） */
    private onWorkLongPress(id: string): void {
        const work = mockWorkStore.findById(id);
        if (!work) {
            return;
        }

        const hasExported = work.exportedAssetUri.length > 0;

        this.getUIContext().showActionSheet({
            title: work.title,
            message: hasExported ? '已导出到相册' : '选择操作',
            sheets: [
                {
                    title: hasExported ? '重新导出到相册' : '导出到相册',
                    action: () => this.exportToGallery(id)
                },
                {
                    title: '删除作品',
                    action: () => this.deleteWork(id)
                }
            ],
            cancel: () => {}
        });
    }

    /** 导出作品到相册 */
    private async exportToGallery(id: string): Promise<void> {
        if (this.exportingWorkId.length > 0) {
            this.toast('正在导出中，请稍候');
            return;
        }

        this.exportingWorkId = id;

        try {
            const result = await WorkSaveService.exportWork(this.context, id);

            if (!result.success) {
                this.toast(result.errorMessage ?? '导出失败');
                this.exportingWorkId = '';
                return;
            }

            if (result.cacheFilePath) {
                const exportResult = await PhotoExportService.saveViaDialog(
                    this.context,
                    result.cacheFilePath,
                    `Vivid_${id}`,
                    this.getExportExtension(id)
                );

                if (exportResult.success) {
                    this.toast('已保存到系统相册「图片」');
                    this.refreshWorks();
                } else if (exportResult.errorCode === 'USER_CANCELLED') {
                    this.toast('已取消导出');
                } else {
                    this.toast(exportResult.errorMessage ?? '导出失败');
                }
            }
        } catch (_err) {
            this.toast('导出失败');
        }

        this.exportingWorkId = '';
    }

    /** 删除作品 */
    private deleteWork(id: string): void {
        this.getUIContext().showAlertDialog({
            title: '确认删除',
            message: '删除后无法恢复，是否继续？',
            primaryButton: {
                value: '取消',
                action: () => {}
            },
            secondaryButton: {
                value: '删除',
                action: () => {
                    // TODO: 接入 WorkRepository 后实现真实删除
                    this.toast('删除功能待接入');
                }
            },
            cancel: () => {}
        });
    }

    /** 获取导出扩展名 */
    private getExportExtension(id: string): string {
        // 根据应用设置返回扩展名
        return 'jpg';
    }

    /** 刷新作品列表 */
    private refreshWorks(): void {
        this.works = mockWorkStore.list();
    }

    /** 显示提示 */
    private toast(message: string): void {
        try {
            this.getUIContext().getPromptAction().showToast({ message });
        } catch (e) {
            // 提示失败不影响操作
        }
    }
}
