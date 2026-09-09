import {
  StickerItem,
  StickerTemplate,
  StickerRenderType,
  ensureFileUri
} from '../../models/EditModels';
import { Theme } from '../common/Theme';
import { HapticService } from '../../services/HapticService';

/**
 * 单个贴纸的渲染 + 手势处理组件。
 *
 * 架构：单向数据流。
 * 本地 @State 驱动交互手势，@Watch('onItemPropChanged') 响应外部数据源更新。
 * 杜绝 @Provide/@Consume 造成的跨实例状态污染与竞态。
 *
 * 手势（GestureGroup Parallel）：
 * - PanGesture(1指)     → 移动
 * - PinchGesture(2指)   → 缩放
 * - RotationGesture(2指) → 旋转
 *
 * 选中态（方案 A：极简文人流）：
 * - 零角标按键（移除全部四角按钮，绝不遮挡印面文字）
 * - 8vp 留白呼吸感朱砂红虚线框（HitTestMode.None，绝不干扰交互）
 * - 多指防冲突协调机制（消除双指缩放/旋转时的单指位移跳变误触）
 * - 统一在底部 StickerPanel 进行高精度微调与删除
 */
@Component
export struct StickerLayer {
  @Watch('onItemPropChanged')
  @Prop item: StickerItem = {
    instanceId: '', templateId: '',
    posX: 0, posY: 0, size: 48,
    rotation: 0, opacity: 1.0, zIndex: 0
  };
  @Prop template: StickerTemplate | null = null;
  @Prop isSelected: boolean = false;
  @Prop active: boolean = true;

  onUpdate: (instanceId: string, posX: number, posY: number, size: number, rotation: number) => void = () => {};
  onSelect: (instanceId: string) => void = () => {};
  onDelete: (instanceId: string) => void = () => {};

  // ── 本地 @State 驱动渲染（不依赖 @Prop 对象引用回读）──
  @State localPosX: number = 0;
  @State localPosY: number = 0;
  @State localSize: number = 48;
  @State localRotation: number = 0;
  @State localOpacity: number = 1.0;

  // ── 手势过程中的临时增量 ──
  @State dragOffsetX: number = 0;
  @State dragOffsetY: number = 0;
  @State pinchScale: number = 1.0;
  @State rotateAngle: number = 0;

  // ── 手势最终值缓存（onActionEnd 中 event 可能归零）──
  @State lastDragX: number = 0;
  @State lastDragY: number = 0;
  @State lastPinchScale: number = 1.0;
  @State lastRotateAngle: number = 0;

  /** 尺寸限制。 */
  private static readonly MIN_SIZE: number = 20;
  private static readonly MAX_SIZE: number = 300;

  // ── 多指手势防冲突协调（方案 A：极简文人流）──
  private isTwoFingerActive: boolean = false;
  private lastTwoFingerEndTime: number = 0;

  aboutToAppear(): void {
    this.syncFromItem();
  }

  private onItemPropChanged(): void {
    this.syncFromItem();
  }

  private syncFromItem(): void {
    this.localPosX = this.item.posX;
    this.localPosY = this.item.posY;
    this.localSize = this.item.size;
    this.localRotation = this.item.rotation;
    this.localOpacity = this.item.opacity;
  }

  private getContentWidth(): number {
    if (this.template?.renderType === StickerRenderType.LabelStrip) {
      return this.localSize * this.pinchScale * 1.6;
    }
    if (this.template?.renderType === StickerRenderType.SealStamp) {
      return this.localSize * this.pinchScale * 0.85;
    }
    return this.localSize * this.pinchScale;
  }

  private getContentHeight(): number {
    if (this.template?.renderType === StickerRenderType.LabelStrip) {
      return this.localSize * this.pinchScale * 0.45;
    }
    if (this.template?.renderType === StickerRenderType.SealStamp) {
      return this.localSize * this.pinchScale * 0.85;
    }
    return this.localSize * this.pinchScale;
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // ── 贴纸内容 ──
      this.stickerContent()

      // ── 选中态高亮边框（方案 A：留白呼吸感虚线框，8vp 留白，零角标）──
      if (this.isSelected && this.active) {
        Column()
          .width(this.getContentWidth() + 16)
          .height(this.getContentHeight() + 16)
          .border({
            width: 1.5,
            color: Theme.SEAL_RED,
            style: BorderStyle.Dashed
          })
          .borderRadius(Theme.RADIUS_DEFAULT)
          .hitTestBehavior(HitTestMode.None)
      }
    }
    .width(this.localSize * this.pinchScale)
    .height(this.localSize * this.pinchScale)
    .position({
      x: this.localPosX + (this.localSize - this.localSize * this.pinchScale) / 2 + this.dragOffsetX,
      y: this.localPosY + (this.localSize - this.localSize * this.pinchScale) / 2 + this.dragOffsetY
    })
    .rotate({ angle: this.localRotation + this.rotateAngle })
    .opacity(this.localOpacity)
    .zIndex(this.item.zIndex > 0 ? this.item.zIndex : 10)
    .hitTestBehavior(this.active ? HitTestMode.Block : HitTestMode.None)
    .onClick((): void => {
      if (this.active) {
        this.onSelect(this.item.instanceId);
      }
    })
    .gesture(GestureGroup(GestureMode.Parallel,
      // ── 单指拖拽 ──
      PanGesture({ fingers: 1 })
        .onActionStart((): void => {
          if (this.isTwoFingerActive || (Date.now() - this.lastTwoFingerEndTime < 200)) {
            return;
          }
          this.dragOffsetX = 0;
          this.dragOffsetY = 0;
          this.lastDragX = 0;
          this.lastDragY = 0;
        })
        .onActionUpdate((event: GestureEvent): void => {
          if (this.isTwoFingerActive || (Date.now() - this.lastTwoFingerEndTime < 200)) {
            this.dragOffsetX = 0;
            this.dragOffsetY = 0;
            this.lastDragX = 0;
            this.lastDragY = 0;
            return;
          }
          if (event !== undefined) {
            this.dragOffsetX = event.offsetX;
            this.dragOffsetY = event.offsetY;
            this.lastDragX = event.offsetX;
            this.lastDragY = event.offsetY;
          }
        })
        .onActionEnd((): void => {
          if (this.isTwoFingerActive || (Date.now() - this.lastTwoFingerEndTime < 200)) {
            this.dragOffsetX = 0;
            this.dragOffsetY = 0;
            this.lastDragX = 0;
            this.lastDragY = 0;
            return;
          }
          // 先提交到本地 @State（立即生效），再通知父组件
          const newX = this.localPosX + this.lastDragX;
          const newY = this.localPosY + this.lastDragY;
          this.localPosX = newX;
          this.localPosY = newY;
          this.item.posX = newX;
          this.item.posY = newY;
          this.dragOffsetX = 0;
          this.dragOffsetY = 0;
          this.lastDragX = 0;
          this.lastDragY = 0;
          this.onUpdate(this.item.instanceId, newX, newY, this.localSize, this.localRotation);
        })
        .onActionCancel((): void => {
          this.dragOffsetX = 0;
          this.dragOffsetY = 0;
          this.lastDragX = 0;
          this.lastDragY = 0;
        }),

      // ── 双指捏合缩放 ──
      PinchGesture({ fingers: 2 })
        .onActionStart((): void => {
          this.isTwoFingerActive = true;
          this.dragOffsetX = 0;
          this.dragOffsetY = 0;
          this.lastDragX = 0;
          this.lastDragY = 0;
          this.pinchScale = 1.0;
          this.lastPinchScale = 1.0;
        })
        .onActionUpdate((event: GestureEvent): void => {
          this.isTwoFingerActive = true;
          if (event !== undefined) {
            this.pinchScale = event.scale;
            this.lastPinchScale = event.scale;
          }
        })
        .onActionEnd((): void => {
          let newSize = Math.round(this.localSize * this.lastPinchScale);
          if (newSize < StickerLayer.MIN_SIZE) {
            newSize = StickerLayer.MIN_SIZE;
          }
          if (newSize > StickerLayer.MAX_SIZE) {
            newSize = StickerLayer.MAX_SIZE;
          }
          const newX = this.localPosX + (this.localSize - newSize) / 2;
          const newY = this.localPosY + (this.localSize - newSize) / 2;
          this.localPosX = newX;
          this.localPosY = newY;
          this.localSize = newSize;
          this.item.posX = newX;
          this.item.posY = newY;
          this.item.size = newSize;
          this.pinchScale = 1.0;
          this.lastPinchScale = 1.0;
          this.isTwoFingerActive = false;
          this.lastTwoFingerEndTime = Date.now();
          this.onUpdate(this.item.instanceId, newX, newY, newSize, this.localRotation);
        })
        .onActionCancel((): void => {
          this.pinchScale = 1.0;
          this.lastPinchScale = 1.0;
          this.isTwoFingerActive = false;
          this.lastTwoFingerEndTime = Date.now();
        }),

      // ── 双指旋转 ──
      RotationGesture({ fingers: 2 })
        .onActionStart((): void => {
          this.isTwoFingerActive = true;
          this.dragOffsetX = 0;
          this.dragOffsetY = 0;
          this.lastDragX = 0;
          this.lastDragY = 0;
          this.rotateAngle = 0;
          this.lastRotateAngle = 0;
        })
        .onActionUpdate((event: GestureEvent): void => {
          this.isTwoFingerActive = true;
          if (event !== undefined) {
            this.rotateAngle = event.angle;
            this.lastRotateAngle = event.angle;
          }
        })
        .onActionEnd((): void => {
          let newRotation = this.localRotation + this.lastRotateAngle;
          while (newRotation > 180) {
            newRotation = newRotation - 360;
          }
          while (newRotation < -180) {
            newRotation = newRotation + 360;
          }
          // 磁吸判断 (0°, 90°, -90°, 180°)
          const SNAP_TARGETS = [0, 90, -90, 180, -180];
          for (let i = 0; i < SNAP_TARGETS.length; i++) {
            const target = SNAP_TARGETS[i];
            if (Math.abs(newRotation - target) <= 3.5) {
              newRotation = (target === -180) ? 180 : target;
              HapticService.triggerTick();
              break;
            }
          }
          const finalRotation = Math.round(newRotation);
          this.localRotation = finalRotation;
          this.item.rotation = finalRotation;
          this.rotateAngle = 0;
          this.lastRotateAngle = 0;
          this.isTwoFingerActive = false;
          this.lastTwoFingerEndTime = Date.now();
          this.onUpdate(this.item.instanceId, this.localPosX, this.localPosY, this.localSize, finalRotation);
        })
        .onActionCancel((): void => {
          this.rotateAngle = 0;
          this.lastRotateAngle = 0;
          this.isTwoFingerActive = false;
          this.lastTwoFingerEndTime = Date.now();
        })
    ))
  }

  /** 根据渲染类型分支绘制贴纸内容。 */
  @Builder
  stickerContent() {
    if (this.item.customUri !== undefined && this.item.customUri !== '') {
      Image(ensureFileUri(this.item.customUri))
        .width(this.localSize * this.pinchScale)
        .height(this.localSize * this.pinchScale)
        .objectFit(ImageFit.Contain)
    } else if (this.template === null) {
      Column()
        .width(this.localSize * this.pinchScale * 0.8)
        .height(this.localSize * this.pinchScale * 0.8)
        .backgroundColor(Theme.OUTLINE_VARIANT)
        .borderRadius(Theme.RADIUS_DEFAULT)
    } else if (this.template.renderType === StickerRenderType.CustomImage) {
      if (this.template.customUri !== undefined && this.template.customUri !== '') {
        Image(ensureFileUri(this.template.customUri))
          .width(this.localSize * this.pinchScale)
          .height(this.localSize * this.pinchScale)
          .objectFit(ImageFit.Contain)
      }
    } else if (this.template.renderType === StickerRenderType.SealStamp) {
      Stack({ alignContent: Alignment.Center }) {
        // 内界阑留白线
        Column()
          .width('86%')
          .height('86%')
          .border({ width: 1, color: 'rgba(255, 255, 255, 0.45)' })
          .hitTestBehavior(HitTestMode.None)

        Text(this.template.textContent)
          .fontFamily('Kai, Noto Serif SC')
          .fontSize(this.localSize * this.pinchScale * 0.42)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.ON_PRIMARY)
      }
      .width(this.localSize * this.pinchScale * 0.85)
      .height(this.localSize * this.pinchScale * 0.85)
      .backgroundColor(Theme.PRIMARY)
      .border({ width: 2, color: Theme.SEAL_RED })
      .shadow({ radius: 6, color: Theme.SHADOW_SM, offsetY: 2 })
    } else if (this.template.renderType === StickerRenderType.CornerFlower) {
      if (this.template.resource !== null) {
        Image(this.template.resource)
          .width(this.localSize * this.pinchScale)
          .height(this.localSize * this.pinchScale)
          .objectFit(ImageFit.Contain)
      }
    } else if (this.template.renderType === StickerRenderType.LabelStrip) {
      Column() {
        Text(this.template.textContent)
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(this.localSize * this.pinchScale * 0.28)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.ON_SURFACE)
          .letterSpacing(2)
      }
      .width(this.localSize * this.pinchScale * 1.6)
      .height(this.localSize * this.pinchScale * 0.45)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(Theme.PAPER_SURFACE)
      .border({ width: 1, color: Theme.OUTLINE_VARIANT })
      .shadow({ radius: 4, color: Theme.SHADOW_SM, offsetY: 1 })
      .responseRegion({ x: '-30%', y: '0%', width: '160%', height: '100%' })
    } else if (this.template.renderType === StickerRenderType.AuspiciousIcon) {
      if (this.template.resource !== null) {
        Image(this.template.resource)
          .width(this.localSize * this.pinchScale)
          .height(this.localSize * this.pinchScale)
          .objectFit(ImageFit.Contain)
      }
    }
  }

}
