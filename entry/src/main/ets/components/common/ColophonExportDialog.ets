import { Theme } from './Theme';
import { WorkRecord } from '../../models/WorkRecord';
import {
  AppraisalSealType,
  APPRAISAL_SEALS,
  AppraisalSealMeta,
  ColophonConfig,
  TraditionalColorItem
} from '../../models/ColophonModels';
import { ColorPaletteExtractor } from '../../services/ColorPaletteExtractor';
import { HapticService } from '../../services/HapticService';
import { PhotoExportService, ExportResult } from '../../services/PhotoExportService';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { MASK_SEAL } from '../MaskSeal';
import { resolveWorkImageSource } from '../../utils/WorkImageUtils';
import { WorkSaveService } from '../../services/WorkSaveService';
import { ColophonScrollRenderer } from '../../services/ColophonScrollRenderer';
import { decodeImageFromUri } from '../../utils/ImageDecodeUtils';
import { ExportProfile } from '../../models/AppSettingsModels';

/**
 * 题跋长卷导出与装裱预览弹窗（东方古风立轴装裱工坊）。
 * 
 * 核心优化：
 * 1. 采用优雅的 94% 底部升起装裱面板，告别悬浮框中框与背景窥露；
 * 2. 彻底移除画心背景处的纯黑黑边框（#101010），原汁原味呈现素宣装裱；
 * 3. 品第印鉴平铺整齐呈现，杜绝字体重叠与右侧截断；
 * 4. 案卷档案号与录入时间采用防挤压优雅排布；
 * 5. 题跋正文与朱砂鉴藏印章舒朗可见，层次井然；
 * 6. 离屏 Canvas 合成全幅题跋立轴长卷海报，SaveButton 直存相册不丢文件。
 */
@Component
export struct ColophonExportDialog {
  @Prop isVisible: boolean = false;
  @Prop work: WorkRecord | null = null;
  onClose: () => void = () => {};

  @State selectedSeal: AppraisalSealType = AppraisalSealType.YUE;
  @State showPalette: boolean = true;
  @State palette: TraditionalColorItem[] = [];
  @State isExporting: boolean = false;

  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

  aboutToAppear(): void {
    this.palette = ColorPaletteExtractor.getDefaultFallbackPalette(5);
  }

  private getSelectedSealGlyph(): string {
    for (let i = 0; i < APPRAISAL_SEALS.length; i++) {
      if (APPRAISAL_SEALS[i].type === this.selectedSeal) {
        return APPRAISAL_SEALS[i].glyph;
      }
    }
    return '阅';
  }

  private getWorkImageSource(): ResourceStr {
    if (this.work === null) {
      return $r('app.media.work_mountain');
    }
    return resolveWorkImageSource(
      this.work.previewImageUri,
      this.work.sourceImageUri,
      this.work.previewImage
    );
  }

  private toast(msg: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: msg });
    } catch (_e) {}
  }

  private safeUnlinkFile(path: string): void {
    try {
      if (fs.accessSync(path)) {
        fs.unlinkSync(path);
      }
    } catch (_e) {}
  }

  private async getSourcePixelMap(): Promise<image.PixelMap | null> {
    if (this.work === null) {
      return null;
    }

    const candidateUris: string[] = [
      this.work.previewImageUri ?? '',
      this.work.sourceImageUri ?? ''
    ];

    for (let i = 0; i < candidateUris.length; i++) {
      let filePath = candidateUris[i].trim();
      if (filePath.length === 0) {
        continue;
      }
      if (filePath.startsWith('file://')) {
        filePath = filePath.substring(7);
      }
      try {
        if (fs.accessSync(filePath)) {
          const decoded = await decodeImageFromUri(filePath, 2048);
          if (decoded && decoded.pixelMap) {
            return decoded.pixelMap;
          }
        }
      } catch (_e) {}
    }

    // 兜底方案：读取内置媒体资源
    try {
      const resourceManager = this.context.resourceManager;
      const mediaBytes = await resourceManager.getMediaContent($r('app.media.work_mountain').id);
      if (mediaBytes && mediaBytes.byteLength > 0) {
        const tmpPath = this.context.cacheDir + `/colophon_src_tmp_${Date.now()}.jpg`;
        const tmpFile = fs.openSync(tmpPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
        fs.writeSync(tmpFile.fd, mediaBytes.buffer.slice(mediaBytes.byteOffset, mediaBytes.byteOffset + mediaBytes.byteLength));
        fs.closeSync(tmpFile.fd);
        try {
          const decoded = await decodeImageFromUri(tmpPath, 2048);
          return decoded.pixelMap;
        } finally {
          this.safeUnlinkFile(tmpPath);
        }
      }
    } catch (_e) {}

    return null;
  }

  private async prepareExportFile(): Promise<string> {
    if (this.work === null) {
      return '';
    }

    // ① 核心：优先完整题跋立轴长卷离屏渲染（画心 + 天头 + 色谱 + 批注 + 朱砂鉴印）
    try {
      const basePixelMap = await this.getSourcePixelMap();
      if (basePixelMap !== null) {
        try {
          const config: ColophonConfig = {
            workTitle: this.work.title || '午后习作',
            fileNo: this.work.id || 'VIVID-001',
            dateText: (this.work.date && this.work.date.length > 0) ? this.work.date : '二〇二六年九月',
            notesText: (this.work.description && this.work.description.length > 0)
              ? this.work.description
              : '此帧光影柔和，层次分明，反差平和，过渡均匀，色彩自然，不事雕琢。',
            sealType: this.selectedSeal,
            showColorPalette: this.showPalette,
            palette: this.palette
          };

          const scrollPixelMap = await ColophonScrollRenderer.renderToPixelMap(
            basePixelMap,
            config,
            this.palette,
            this.selectedSeal
          );

          if (scrollPixelMap !== null) {
            const profile: ExportProfile = {
              mimeType: 'image/jpeg',
              extension: '.jpg',
              maxLongEdge: 0,
              encoderQuality: 95
            };
            const encodedPath = await PhotoExportService.encodeToCacheFile(this.context, scrollPixelMap, profile);
            scrollPixelMap.release();
            if (encodedPath && encodedPath.length > 0 && fs.accessSync(encodedPath)) {
              return encodedPath;
            }
          }
        } finally {
          basePixelMap.release();
        }
      }
    } catch (_err) {
      // 离屏渲染异常时自动降级到备选文件，绝不阻塞用户导出
    }

    // ② 优雅降级方案一：尝试通过 WorkSaveService 导出原装裱作品
    if (this.work.id && this.work.id.length > 0 && this.work.sourceImageUri && this.work.sourceImageUri.length > 0) {
      try {
        const renderRes = await WorkSaveService.exportWork(this.context, this.work.id);
        if (renderRes.success && renderRes.cacheFilePath && renderRes.cacheFilePath.length > 0) {
          let rawRenderPath = renderRes.cacheFilePath;
          if (rawRenderPath.startsWith('file://')) {
            rawRenderPath = rawRenderPath.substring(7);
          }
          if (fs.accessSync(rawRenderPath)) {
            return rawRenderPath;
          }
        }
      } catch (_err) {}
    }

    // ③ 优雅降级方案二：从现有 previewImageUri 或 sourceImageUri 提取物理文件并拷贝到 cacheDir
    const candidateUris: string[] = [
      this.work.previewImageUri ?? '',
      this.work.sourceImageUri ?? ''
    ];

    for (let i = 0; i < candidateUris.length; i++) {
      const rawUri = candidateUris[i].trim();
      if (rawUri.length === 0) {
        continue;
      }

      let filePath = rawUri;
      if (filePath.startsWith('file://')) {
        filePath = filePath.substring(7);
      }

      try {
        if (fs.accessSync(filePath)) {
          // 必须拷贝至临时文件：因为 PhotoExportService 在写入相册后会 unlink 删除该临时文件
          const destCachePath = this.context.cacheDir + `/colophon_export_${Date.now()}_${i}.jpg`;
          fs.copyFileSync(filePath, destCachePath);
          return destCachePath;
        }
      } catch (_e) {}
    }

    // ④ 优雅降级方案三：如果是内置 resource 图片（如 sample/mock 作品）
    try {
      const resourceManager = this.context.resourceManager;
      const mediaBytes = await resourceManager.getMediaContent($r('app.media.work_mountain').id);
      if (mediaBytes && mediaBytes.byteLength > 0) {
        const fallbackPath = this.context.cacheDir + `/colophon_fallback_${Date.now()}.jpg`;
        const fallbackFile = fs.openSync(fallbackPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
        fs.writeSync(fallbackFile.fd, mediaBytes.buffer.slice(mediaBytes.byteOffset, mediaBytes.byteOffset + mediaBytes.byteLength));
        fs.closeSync(fallbackFile.fd);
        return fallbackPath;
      }
    } catch (_e) {}

    return '';
  }

  private async handleExport(useSaveButton: boolean): Promise<void> {
    if (this.isExporting || this.work === null) {
      return;
    }
    this.isExporting = true;
    HapticService.triggerImpact();

    try {
      const cachePath = await this.prepareExportFile();
      if (!cachePath || cachePath.length === 0) {
        this.toast('卷宗图像源准备失败');
        this.isExporting = false;
        return;
      }

      let result: ExportResult;
      if (useSaveButton) {
        result = await PhotoExportService.saveViaSaveButton(this.context, cachePath, false);
        if (!result.success) {
          result = await PhotoExportService.saveViaDialog(this.context, cachePath, 'Colophon_' + this.work.id, 'jpg');
        }
      } else {
        result = await PhotoExportService.saveViaDialog(this.context, cachePath, 'Colophon_' + this.work.id, 'jpg');
      }

      if (result.success) {
        this.toast('题跋长卷已保存至系统相册');
        this.onClose();
      } else if (result.errorCode === 'USER_CANCELLED') {
        this.toast('已取消保存');
      } else {
        this.toast(result.errorMessage ?? '保存失败');
      }
    } catch (_err) {
      this.toast('题跋长卷导出失败');
    } finally {
      this.isExporting = false;
    }
  }

  build() {
    if (this.isVisible && this.work !== null) {
      Stack({ alignContent: Alignment.Bottom }) {
        // ① 半透明背景遮罩（带温润模糊）
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(36, 25, 24, 0.68)')
          .backdropBlur(10)
          .onClick(() => {
            if (!this.isExporting) {
              this.onClose();
            }
          });

        // ② 装裱工坊主面板（94% 屏高底部升起，格局从容）
        Column() {
          // 顶部标题栏
          Row() {
            Row({ space: 6 }) {
              Text('装裱')
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor(MASK_SEAL.sealRed)
                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                .border({ width: 1, color: MASK_SEAL.sealRed })
                .borderRadius(2);

              Text('题跋长卷 · 案卷装裱')
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(MASK_SEAL.ink);
            }

            Blank();

            // 关闭按钮
            Text('✕')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(18)
              .fontColor(MASK_SEAL.inkMuted)
              .padding({ left: 8, right: 4, top: 4, bottom: 4 })
              .onClick(() => {
                if (!this.isExporting) {
                  this.onClose();
                }
              });
          }
          .width('100%')
          .padding({ left: 18, right: 16, top: 14, bottom: 12 })
          .border({ width: { bottom: 1 }, color: '#e5ded9' });

          // 中间：立轴长卷预览视口（全画幅舒展展示）
          Scroll() {
            Column({ space: 0 }) {
              // 古典立轴长卷纸心
              Column({ space: 14 }) {
                // 1. 天头题签
                Column({ space: 6 }) {
                  Text(this.work.title || '午后习作')
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(MASK_SEAL.ink)
                    .letterSpacing(2);
                  Row()
                    .width(44)
                    .height(1.5)
                    .backgroundColor(MASK_SEAL.primary);
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)
                .padding({ top: 18 });

                // 2. 画心装裱图片（彻底移除黑框！居中纯净展现画心）
                Image(this.getWorkImageSource())
                  .width('100%')
                  .objectFit(ImageFit.Contain)
                  .border({ width: 1, color: '#d9c4c0' })
                  .borderRadius(2)
                  .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.08)', offsetY: 2 });

                // 3. 案卷档案号与录入日期（防重叠排版）
                Row() {
                  Text('案卷 · ' + (this.work.id.length > 18 ? this.work.id.substring(0, 16) + '…' : this.work.id))
                    .fontFamily(Theme.FONT_MONO)
                    .fontSize(10)
                    .fontColor(MASK_SEAL.inkMuted)
                    .layoutWeight(1)
                    .maxLines(1);

                  Text('录于 · ' + (this.work.date && this.work.date.length > 0 ? this.work.date : '二〇二六年九月'))
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(10)
                    .fontColor(MASK_SEAL.inkMuted);
                }
                .width('100%')
                .padding({ left: 4, right: 4 });

                // 4. 国色五谱展示带
                if (this.showPalette && this.palette.length > 0) {
                  Row({ space: 6 }) {
                    ForEach(this.palette, (item: TraditionalColorItem) => {
                      Column({ space: 3 }) {
                        Row()
                          .width('100%')
                          .height(16)
                          .backgroundColor(item.hex)
                          .borderRadius(2);
                        Text(item.name)
                          .fontFamily(Theme.FONT_SERIF)
                          .fontSize(10)
                          .fontColor(MASK_SEAL.ink);
                        Text(item.hex)
                          .fontFamily(Theme.FONT_MONO)
                          .fontSize(8)
                          .fontColor(MASK_SEAL.inkMuted);
                      }
                      .layoutWeight(1)
                      .padding(4)
                      .backgroundColor(MASK_SEAL.paperSurface)
                      .border({ width: 1, color: '#e5ded9' })
                      .borderRadius(2);
                    })
                  }
                  .width('100%');
                }

                // 5. 案卷批注与朱砂鉴藏印章
                Stack({ alignContent: Alignment.BottomEnd }) {
                  Column({ space: 8 }) {
                    Row({ space: 6 }) {
                      Row().width(3).height(14).backgroundColor(MASK_SEAL.primary);
                      Text('案卷批注')
                        .fontFamily(Theme.FONT_SERIF)
                        .fontSize(13)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(MASK_SEAL.ink);
                    }

                    Text(this.work.description && this.work.description.length > 0 ?
                      this.work.description : '此帧光影柔和，层次分明，反差平和，过渡均匀，色彩自然，不事雕琢。')
                      .fontFamily(Theme.FONT_SERIF)
                      .fontSize(13)
                      .fontColor(MASK_SEAL.ink)
                      .lineHeight(20);
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                  .padding({ left: 12, right: 12, top: 12, bottom: 28 })
                  .backgroundColor(MASK_SEAL.paperSurface)
                  .border({ width: 1, color: '#d9c4c0' });

                  // 鉴藏大印（落款右下角）
                  Stack({ alignContent: Alignment.Center }) {
                    Text(this.getSelectedSealGlyph())
                      .fontFamily(Theme.FONT_SERIF)
                      .fontSize(22)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(MASK_SEAL.sealRed);
                  }
                  .width(42)
                  .height(42)
                  .backgroundColor('#faebe9')
                  .border({ width: 1.5, color: MASK_SEAL.sealRed })
                  .borderRadius(2)
                  .margin({ right: 10, bottom: 8 });
                }
                .width('100%');

                // 6. 底栏落款
                Text('微霏格物局 · 炎国宝卷')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(11)
                  .fontColor(MASK_SEAL.inkMuted)
                  .letterSpacing(2)
                  .padding({ bottom: 8 });
              }
              .width('100%')
              .padding(14)
              .backgroundColor('#f4ede6')
              .border({ width: 1, color: '#d3c5bf' })
              .borderRadius(4);
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 });
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true });

          // 底部控制面板（品第印鉴 + 国色五谱开关 + 保存操作）
          Column({ space: 10 }) {
            // 印章选择与国色开关（紧凑雅致同一区域）
            Column({ space: 8 }) {
              Row() {
                Text('品第鉴印')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(12)
                  .fontColor(MASK_SEAL.inkMuted);

                Blank();

                Row({ space: 6 }) {
                  Text('提炼国色五谱')
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(12)
                    .fontColor(MASK_SEAL.inkMuted);
                  Toggle({ type: ToggleType.Switch, isOn: this.showPalette })
                    .selectedColor(Theme.PRIMARY)
                    .switchPointColor(Theme.PAPER_SURFACE)
                    .onChange((isOn: boolean) => {
                      this.showPalette = isOn;
                    });
                }
              }
              .width('100%')
              .alignItems(VerticalAlign.Center);

              // 5 枚印鉴平铺单行排布，杜绝截断与重复字符
              Row({ space: 8 }) {
                ForEach(APPRAISAL_SEALS, (seal: AppraisalSealMeta) => {
                  Column({ space: 3 }) {
                    Stack({ alignContent: Alignment.Center }) {
                      Text(seal.glyph)
                        .fontFamily(Theme.FONT_SERIF)
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(this.selectedSeal === seal.type ? MASK_SEAL.sealRed : MASK_SEAL.inkMuted);
                    }
                    .width(44)
                    .height(36)
                    .backgroundColor(this.selectedSeal === seal.type ? '#faebe9' : MASK_SEAL.paperSurface)
                    .border({
                      width: this.selectedSeal === seal.type ? 1.5 : 1,
                      color: this.selectedSeal === seal.type ? MASK_SEAL.sealRed : '#d9c4c0'
                    })
                    .borderRadius(3);

                    Text(seal.label)
                      .fontFamily(Theme.FONT_SERIF)
                      .fontSize(10)
                      .fontColor(this.selectedSeal === seal.type ? MASK_SEAL.primary : MASK_SEAL.inkMuted);
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Center)
                  .onClick(() => {
                    HapticService.triggerImpact();
                    this.selectedSeal = seal.type;
                  });
                }, (seal: AppraisalSealMeta) => seal.type)
              }
              .width('100%');
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 10, bottom: 10 })
            .backgroundColor('#f7f2ed')
            .border({ width: 1, color: '#ded5cf' })
            .borderRadius(6);

            // 底部按钮栏：返回 + 保存至系统相册
            Row({ space: 12 }) {
              Button('返回')
                .type(ButtonType.Normal)
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(15)
                .fontColor(MASK_SEAL.ink)
                .backgroundColor('#efe7e2')
                .border({ width: 1, color: '#d9cdc7' })
                .height(44)
                .layoutWeight(1)
                .borderRadius(4)
                .onClick(() => {
                  if (!this.isExporting) {
                    this.onClose();
                  }
                });

              Stack({ alignContent: Alignment.Center }) {
                SaveButton({
                  text: SaveDescription.SAVE,
                  buttonType: ButtonType.Normal
                })
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .backgroundColor(MASK_SEAL.primary)
                  .borderRadius(4)
                  .width('100%')
                  .height(44)
                  .onClick((event: ClickEvent, result: SaveButtonOnClickResult) => {
                    this.handleExport(result === SaveButtonOnClickResult.SUCCESS);
                  });
              }
              .layoutWeight(1)
              .height(44);
            }
            .width('100%');
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 10, bottom: 16 })
          .backgroundColor(MASK_SEAL.paperSurface)
          .border({ width: { top: 1 }, color: '#ded5cf' });
        }
        .width('100%')
        .height('94%')
        .backgroundColor(MASK_SEAL.paperSurface)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .shadow({ radius: 24, color: 'rgba(0, 0, 0, 0.35)', offsetY: -6 });
      }
      .width('100%')
      .height('100%')
      .zIndex(999);
    }
  }
}
