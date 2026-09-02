import { FILTER_PRESETS } from './FilterCatalog';
import {
  clampFilterStrength,
  createDefaultFilterEditState,
  FilterEditState,
  FilterPreset
} from './FilterModels';

/** The edit-state slice introduced by the V1 filter feature. */
export interface EditState {
  filter: FilterEditState;
}

export function createDefaultEditState(): EditState {
  return {
    filter: createDefaultFilterEditState()
  };
}

/** Start a fresh non-destructive edit session for another photo. */
export function resetEditStateForPhoto(): EditState {
  return createDefaultEditState();
}

/** Select a known preset and apply only that preset's declared default strength. */
export function selectFilter(
  state: EditState,
  filterId: string,
  presets: FilterPreset[] = FILTER_PRESETS
): EditState {
  const preset = presets.find((item: FilterPreset) => item.id === filterId);
  if (preset === undefined) {
    return state;
  }
  return {
    filter: {
      filterId: preset.id,
      strength: clampFilterStrength(preset.defaultStrength)
    }
  };
}

/** Change only strength, retaining the selected preset. */
export function setFilterStrength(state: EditState, value: number): EditState {
  return {
    filter: {
      filterId: state.filter.filterId,
      strength: clampFilterStrength(value)
    }
  };
}
