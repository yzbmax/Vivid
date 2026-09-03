import { TextLayer as TextLayerModel } from '../../models/SharedContracts';
import {
  ContentRect,
  ResolvedTextLayout,
  draggedCenterToNormalized,
  resolveTextLayout
} from '../../features/editor/text/TextLayoutResolver';
import { findFontEntry, resolveFontKey } from '../../features/editor/text/FontCatalog';
import { createDefaultTextLayer } from '../../features/editor/text/TextLayerState';
import { Theme } from '../common/Theme';

/** 文字图层预览：始终显示文字，仅在文字工具激活时允许选中和拖动。 */
@Component
export struct TextLayer {
  @Prop layers: TextLayerModel[] = [];
  @Prop selectedId: string = '';
  @Prop active: boolean = false;
  @Prop isComparing: boolean = false;
  @Prop contentRect: ContentRect = { x: 0, y: 0, width: 0, height: 0 };
  @Prop unavailableFontKeys: string[] = [];
  onSelect: (id: string) => void = () => {};
  onMove: (id: string, centerX: number, centerY: number) => void = () => {};

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.layers, (_layer: TextLayerModel, index: number) => {
        // 从响应式数组读取最新值，不让 Builder 闭包停留在首次创建的图层对象。
        TextLayerItem({
          layout: this.layerLayout(this.layers[index]),
          family: this.fontFamily(this.layers[index].fontKey),
          selected: this.selectedId === this.layers[index].id,
          active: this.active && !this.isComparing,
          contentRect: { x: 0, y: 0, width: this.contentRect.width, height: this.contentRect.height },
          onSelect: this.onSelect,
          onMove: this.onMove
        }).zIndex(index)
      }, (layer: TextLayerModel) => layer.id)
    }
    .width(this.contentRect.width)
    .height(this.contentRect.height)
    .position({ x: this.contentRect.x, y: this.contentRect.y })
    .clip(true)
    .opacity(this.isComparing ? 0 : 1)
    .hitTestBehavior(this.active && !this.isComparing ? HitTestMode.Transparent : HitTestMode.None)
  }

  private fontFamily(fontKey: string): string {
    const entry = findFontEntry(resolveFontKey(fontKey, this.unavailableFontKeys));
    return entry === null ? 'HarmonyOS Sans SC' : entry.family;
  }

  private layerLayout(layer: TextLayerModel): ResolvedTextLayout {
    const rect: ContentRect = { x: 0, y: 0, width: this.contentRect.width, height: this.contentRect.height };
    const layout = resolveTextLayout(rect, layer);
    try {
      const context = this.getUIContext();
      const measured = context.getMeasureUtils().measureTextSize({
        textContent: layer.content.replace(/\r\n|\r/g, '\n'),
        fontFamily: this.fontFamily(layer.fontKey),
        fontSize: layout.fontSizePx + 'vp',
        lineHeight: layout.fontSizePx * 1.25 + 'vp'
      });
      return resolveTextLayout(rect, layer, {
        width: Math.ceil(context.px2vp(Number(measured.width))) + 2,
        height: Math.ceil(context.px2vp(Number(measured.height)))
      });
    } catch (_err) {
      // 测量不可用时使用纯逻辑的保守全角包围盒，不记录用户文字。
      return layout;
    }
  }
}

/** 单层保留稳定组件身份，父层不可变更新通过 @Prop 刷新显示与手势。 */
@Component
struct TextLayerItem {
  @Prop layout: ResolvedTextLayout = resolveTextLayout(
    { x: 0, y: 0, width: 0, height: 0 }, createDefaultTextLayer(''));
  @Prop family: string = 'HarmonyOS Sans SC';
  @Prop selected: boolean = false;
  @Prop @Watch('cancelDrag') active: boolean = false;
  @Prop contentRect: ContentRect = { x: 0, y: 0, width: 0, height: 0 };
  onSelect: (id: string) => void = () => {};
  onMove: (id: string, centerX: number, centerY: number) => void = () => {};

  @State private dragX: number = 0;
  @State private dragY: number = 0;
  @State private lastDragX: number = 0;
  @State private lastDragY: number = 0;
  @State private dragLayerId: string = '';

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Text(this.layout.content.replace(/\r\n|\r/g, '\n'))
        .fontFamily(this.family)
        .fontSize(this.layout.fontSizePx + 'vp')
        .fontColor(this.argbToHex(this.layout.colorArgb))
        .opacity(this.layout.opacity)
        .maxLines(3)
        .textAlign(TextAlign.Center)
        .lineHeight(this.layout.fontSizePx * 1.25 + 'vp')
        .width(this.layout.widthPx)
        .height(this.layout.heightPx)
      if (this.active && this.selected) {
        Column()
          .width(this.layout.widthPx + 12)
          .height(this.layout.heightPx + 12)
          .border({ width: 1, color: Theme.SEAL_RED })
          .hitTestBehavior(HitTestMode.None)
      }
    }
    .width(this.layout.widthPx + 12)
    .height(this.layout.heightPx + 12)
    .position({
      x: this.layout.centerPixelX - this.layout.widthPx / 2 - 6 + this.dragX,
      y: this.layout.centerPixelY - this.layout.heightPx / 2 - 6 + this.dragY
    })
    .rotate({ angle: this.layout.rotationDeg })
    .hitTestBehavior(this.active ? HitTestMode.Block : HitTestMode.None)
    .onClick(() => {
      if (this.active) {
        this.onSelect(this.layout.id);
      }
    })
    .gesture(PanGesture({ fingers: 1 })
      .onActionStart(() => {
        if (this.active) {
          this.dragLayerId = this.layout.id;
          this.dragX = 0;
          this.dragY = 0;
          this.lastDragX = 0;
          this.lastDragY = 0;
          this.onSelect(this.layout.id);
        }
      })
      .onActionUpdate((event: GestureEvent) => {
        if (this.active && this.dragLayerId === this.layout.id && event !== undefined) {
          const center = draggedCenterToNormalized(this.contentRect, this.layout,
            this.layout.centerPixelX + event.offsetX, this.layout.centerPixelY + event.offsetY);
          this.dragX = center.x * this.contentRect.width - this.layout.centerPixelX;
          this.dragY = center.y * this.contentRect.height - this.layout.centerPixelY;
          this.lastDragX = event.offsetX;
          this.lastDragY = event.offsetY;
        }
      })
      .onActionEnd(() => {
        if (this.active && this.dragLayerId === this.layout.id) {
          const normalized = draggedCenterToNormalized(
            this.contentRect,
            this.layout,
            this.layout.centerPixelX + this.lastDragX,
            this.layout.centerPixelY + this.lastDragY
          );
          this.onMove(this.layout.id, normalized.x, normalized.y);
        }
        this.cancelDrag();
      })
      .onActionCancel(() => this.cancelDrag())
    )
  }

  private cancelDrag(): void {
    this.dragLayerId = '';
    this.dragX = 0;
    this.dragY = 0;
    this.lastDragX = 0;
    this.lastDragY = 0;
  }

  private argbToHex(argb: number): string {
    const r = (argb >> 16) & 0xFF;
    const g = (argb >> 8) & 0xFF;
    const b = argb & 0xFF;
    const hex = (value: number): string => {
      const text = value.toString(16);
      return text.length < 2 ? '0' + text : text;
    };
    return '#' + hex(r) + hex(g) + hex(b);
  }
}
