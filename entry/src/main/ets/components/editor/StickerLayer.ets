import {
  StickerItem,
  StickerTemplate,
  StickerRenderType
} from '../../models/EditModels';
import { Theme } from '../common/Theme';

/**
 * 单个贴纸的渲染 + 手势处理组件。
 *
 * 架构：本地 @State 驱动渲染，@Watch 同步父组件变化。
 * 解决 ArkUI ForEach 中 @Prop 更新不触发子组件重渲染的问题。
 *
 * 渲染逻辑（按 renderType 分支）：
 * - SealStamp   → 红底白字方框（复用 SealBadge 模式）
 * - CornerFlower → Image(resource)
 * - LabelStrip  → 宣纸底+墨字条
 * - AuspiciousIcon → Image(resource)
 *
 * 手势（GestureGroup Parallel）：
 * - PanGesture(1指)     → 移动
 * - PinchGesture(2指)   → 缩放
 * - RotationGesture(2指) → 旋转
 *
 * 选中态：SEAL_RED 四角括号。
 */
@Component
export struct StickerLayer {
  @Prop item: StickerItem = {
    instanceId: '', templateId: '',
    posX: 0, posY: 0, size: 48,
    rotation: 0, opacity: 1.0, zIndex: 0
  };
  @Prop template: StickerTemplate | null = null;
  @Prop isSelected: boolean = false;

  // ── 滑块目标值（通过 @Provide/@Consume 跨层级响应式传递，不受 ForEach 复用影响）──
  @Watch('onTargetSizeChanged')
  @Consume stickerTargetSize: number;
  @Watch('onTargetRotationChanged')
  @Consume stickerTargetRotation: number;
  @Watch('onTargetOpacityChanged')
  @Consume stickerTargetOpacity: number;

  onUpdate: (instanceId: string, posX: number, posY: number, size: number, rotation: number) => void = () => {};
  onSelect: (instanceId: string) => void = () => {};

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

  aboutToAppear(): void {
    // 仅初始化时从 @Prop item 读取一次初始值
    this.localPosX = this.item.posX;
    this.localPosY = this.item.posY;
    this.localSize = this.item.size;
    this.localRotation = this.item.rotation;
    this.localOpacity = this.item.opacity;
  }

  // ── @Watch 回调：面板滑块更新时同步到本地 @State（仅选中贴纸响应）──
  private onTargetSizeChanged(): void {
    if (this.isSelected && this.stickerTargetSize >= 0) {
      this.localSize = this.stickerTargetSize;
    }
  }

  private onTargetRotationChanged(): void {
    if (this.isSelected && this.stickerTargetRotation > -999) {
      this.localRotation = this.stickerTargetRotation;
    }
  }

  private onTargetOpacityChanged(): void {
    if (this.isSelected && this.stickerTargetOpacity >= 0) {
      this.localOpacity = this.stickerTargetOpacity;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // ── 贴纸内容 ──
      this.stickerContent()
    }
    .width(this.localSize * this.pinchScale)
    .height(this.localSize * this.pinchScale)
    .position({
      x: this.localPosX + this.dragOffsetX,
      y: this.localPosY + this.dragOffsetY
    })
    .rotate({ angle: this.localRotation + this.rotateAngle })
    .opacity(this.localOpacity)
    .zIndex(this.item.zIndex)
    .onClick(() => {
      this.onSelect(this.item.instanceId);
    })
    .gesture(GestureGroup(GestureMode.Parallel,
      // ── 单指拖拽 ──
      PanGesture({ fingers: 1 })
        .onActionStart(() => {
          this.dragOffsetX = 0;
          this.dragOffsetY = 0;
          this.lastDragX = 0;
          this.lastDragY = 0;
        })
        .onActionUpdate((event: GestureEvent) => {
          if (event !== undefined) {
            this.dragOffsetX = event.offsetX;
            this.dragOffsetY = event.offsetY;
            this.lastDragX = event.offsetX;
            this.lastDragY = event.offsetY;
          }
        })
        .onActionEnd(() => {
          // 先提交到本地 @State（立即生效），再通知父组件
          const newX = this.localPosX + this.lastDragX;
          const newY = this.localPosY + this.lastDragY;
          this.localPosX = newX;
          this.localPosY = newY;
          this.dragOffsetX = 0;
          this.dragOffsetY = 0;
          this.lastDragX = 0;
          this.lastDragY = 0;
          this.onUpdate(this.item.instanceId, newX, newY, this.localSize, this.localRotation);
        }),

      // ── 双指捏合缩放 ──
      PinchGesture({ fingers: 2 })
        .onActionStart(() => {
          this.pinchScale = 1.0;
          this.lastPinchScale = 1.0;
        })
        .onActionUpdate((event: GestureEvent) => {
          if (event !== undefined) {
            this.pinchScale = event.scale;
            this.lastPinchScale = event.scale;
          }
        })
        .onActionEnd(() => {
          let newSize = Math.round(this.localSize * this.lastPinchScale);
          if (newSize < StickerLayer.MIN_SIZE) {
            newSize = StickerLayer.MIN_SIZE;
          }
          if (newSize > StickerLayer.MAX_SIZE) {
            newSize = StickerLayer.MAX_SIZE;
          }
          this.localSize = newSize;
          this.pinchScale = 1.0;
          this.lastPinchScale = 1.0;
          this.onUpdate(this.item.instanceId, this.localPosX, this.localPosY, newSize, this.localRotation);
        }),

      // ── 双指旋转 ──
      RotationGesture({ fingers: 2 })
        .onActionStart(() => {
          this.rotateAngle = 0;
          this.lastRotateAngle = 0;
        })
        .onActionUpdate((event: GestureEvent) => {
          if (event !== undefined) {
            this.rotateAngle = event.angle;
            this.lastRotateAngle = event.angle;
          }
        })
        .onActionEnd(() => {
          let newRotation = this.localRotation + this.lastRotateAngle;
          if (newRotation > 180) {
            newRotation = newRotation - 360;
          }
          if (newRotation < -180) {
            newRotation = newRotation + 360;
          }
          this.localRotation = newRotation;
          this.rotateAngle = 0;
          this.lastRotateAngle = 0;
          this.onUpdate(this.item.instanceId, this.localPosX, this.localPosY, this.localSize, newRotation);
        })
    ))
  }

  /** 根据渲染类型分支绘制贴纸内容。 */
  @Builder
  stickerContent() {
    if (this.item.customUri !== undefined && this.item.customUri !== '') {
      Image(this.item.customUri)
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
        Image(this.template.customUri)
          .width(this.localSize * this.pinchScale)
          .height(this.localSize * this.pinchScale)
          .objectFit(ImageFit.Contain)
      }
    } else if (this.template.renderType === StickerRenderType.SealStamp) {
      Stack({ alignContent: Alignment.Center }) {
        Text(this.template.textContent)
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(this.localSize * this.pinchScale * 0.42)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.ON_PRIMARY)
      }
      .width(this.localSize * this.pinchScale * 0.85)
      .height(this.localSize * this.pinchScale * 0.85)
      .backgroundColor(Theme.PRIMARY)
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
