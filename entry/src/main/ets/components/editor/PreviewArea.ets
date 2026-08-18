import { AdjustEffects, AdjustParams, mapParamsToEffects } from '../../models/EditModels';
import { Theme } from '../common/Theme';

/**
 * 预览区：照片 + 装裱边框 + 原图对比按压层。
 *
 * 效果：曝光/亮度 → 明暗覆盖层；对比度/饱和度 → 组件 contrast()/saturate()。
 * 原图对比（isComparing=true）时隐藏全部效果，显示原图。
 * imageSrc 为空时显示占位（如 source=work 待 B 的 WorkRecord 源图字段接入）。
 */
@Component
export struct PreviewArea {
  @Prop imageSrc: string = '';
  @Prop params: AdjustParams = { exposure: 0, brightness: 0, contrast: 0, saturation: 0 };
  @Prop isComparing: boolean = false;
  onCompareChange: (down: boolean) => void = () => {};

  build() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        // 照片（Contain 保持原比例、不裁切，铺满可用区）
        if (this.imageSrc !== '') {
          Image(this.imageSrc)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .contrast(this.isComparing ? 1 : this.effects().contrast)
            .saturate(this.isComparing ? 1 : this.effects().saturate)
        } else {
          Column({ space: 8 }) {
            Text('预览区占位')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
              .fontWeight(600)
              .fontColor(Theme.ON_SURFACE)
            Text('作品源图恢复待 WorkRecord 字段接入')
              .fontFamily(Theme.FONT_SANS)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_SURFACE_VARIANT_70)
              .textAlign(TextAlign.Center)
          }
          .padding(24)
        }

        // 明暗覆盖层（曝光/亮度）
        if (!this.isComparing && this.imageSrc !== '' && this.effects().luminanceAlpha > 0) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(this.effects().luminanceLight ? '#FFFFFF' : '#000000')
            .opacity(this.effects().luminanceAlpha)
            .hitTestBehavior(HitTestMode.None)
        }

        // 装裱边框：外层细线 + 内衬留白 + 朱砂内线（直角偏方）
        Column() {
          Column()
            .width('100%')
            .height('100%')
            .border({ width: 1, color: Theme.PRIMARY_20 })
        }
        .width('100%')
        .height('100%')
        .border({ width: 1, color: Theme.OUTLINE_VARIANT })
        .padding(8)
        .hitTestBehavior(HitTestMode.None)

        // 原图对比提示胶囊
        if (this.isComparing) {
          Text('原图')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
            .fontColor(Theme.ON_PRIMARY)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor(Theme.PRIMARY)
            .borderRadius(Theme.RADIUS_FULL)
        }
      }
      .width('100%')
      .height('100%')
      .clip(true)
      .backgroundColor(Theme.SURFACE_CONTAINER_LOWEST)
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.onCompareChange(true);
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.onCompareChange(false);
        }
      })
    }
    .width('100%')
    .height('100%')
  }

  private effects(): AdjustEffects {
    return mapParamsToEffects(this.params);
  }
}
