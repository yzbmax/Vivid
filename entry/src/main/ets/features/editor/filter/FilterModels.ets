/** V1 LUT preset metadata. UI and render code consume this data-driven model. */
export interface FilterPreset {
  id: string;
  name: string;
  lutPath?: string;
  defaultStrength: number;
  version: number;
}

/** Non-destructive filter edit state; strength is always normalized to [0, 1]. */
export interface FilterEditState {
  filterId: string;
  strength: number;
}

/** Clamp a UI or persisted strength before it enters the edit state. */
export function clampFilterStrength(value: number): number {
  return Math.max(0, Math.min(1, value));
}

/** Return a fresh original-filter state for a new photo session. */
export function createDefaultFilterEditState(): FilterEditState {
  return {
    filterId: 'original',
    strength: 0
  };
}
