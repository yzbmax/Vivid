import { EditorToolKey } from '../../models/EditModels';

// 首页数据模型：定义"技艺列表"与"近作列表"的数据结构。
// 由 HomePage 实例化后通过 @Prop 单向传入各子组件。

/**
 * 技艺条目：用于 ProcessSection（技艺列表区）。
 * - title: 条目标题（如"AI 自动识别主体"）
 * - desc:  条目描述（如"智能勾勒主体轮廓，一键建立精确蒙版"）
 * - iconPath: SVG 路径命令字符串，用 Path().commands() 绘制图标
 */
export class FeatureItem {
  title: ResourceStr;
  desc: ResourceStr;
  iconPath: string;

  constructor(title: ResourceStr, desc: ResourceStr, iconPath: string) {
    this.title = title;
    this.desc = desc;
    this.iconPath = iconPath;
  }
}

/**
 * 近作条目：用于 RecentWorkSection（近作横滑区）。
 * - title: 作品标题（如"远山"）
 * - date:  作品日期（如"2026 · 07"）
 */
export class WorkItem {
  title: ResourceStr;
  date: ResourceStr;

  constructor(title: ResourceStr, date: ResourceStr) {
    this.title = title;
    this.date = date;
  }
}

/**
 * 快捷功能条目：用于 QuickToolsSection（快捷功能区）。
 * - name: 功能名称（如"智能抠图"）
 * - iconPath: SVG 路径命令字符串，用 Path().commands() 绘制图标
 * - isHot: 是否显示"热"角标
 */
export class ToolItem {
  key: EditorToolKey;
  name: ResourceStr;
  icon: Resource;
  isHot: boolean;

  constructor(key: EditorToolKey, name: ResourceStr, icon: Resource, isHot: boolean = false) {
    this.key = key;
    this.name = name;
    this.icon = icon;
    this.isHot = isHot;
  }
}
