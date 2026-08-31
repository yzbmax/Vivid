import { FILTER_PRESETS } from './FilterCatalog';
import { FilterPreset } from './FilterModels';
import {
  createDefaultEditState,
  EditState,
  resetEditStateForPhoto,
  selectFilter,
  setFilterStrength
} from './FilterState';

/**
 * UI-facing filter coordinator. It owns state transitions and render tokens;
 * native work remains injected by the page so this class stays deterministic.
 */
export class FilterController {
  private state: EditState = createDefaultEditState();
  private renderGeneration: number = 0;

  getState(): EditState {
    return this.state;
  }

  resetForPhoto(): EditState {
    this.state = resetEditStateForPhoto();
    this.cancelPendingRender();
    return this.state;
  }

  selectFilter(filterId: string): EditState {
    this.state = selectFilter(this.state, filterId, FILTER_PRESETS);
    return this.state;
  }

  setStrength(value: number): EditState {
    this.state = setFilterStrength(this.state, value);
    return this.state;
  }

  preset(filterId: string): FilterPreset | undefined {
    return FILTER_PRESETS.find((item: FilterPreset) => item.id === filterId);
  }

  beginRender(): number {
    this.renderGeneration += 1;
    return this.renderGeneration;
  }

  cancelPendingRender(): number {
    this.renderGeneration += 1;
    return this.renderGeneration;
  }

  isCurrent(generation: number): boolean {
    return this.renderGeneration === generation;
  }
}
