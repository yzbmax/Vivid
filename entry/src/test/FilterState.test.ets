import { describe, it, expect } from '@ohos/hypium';
import {
  createDefaultEditState,
  resetEditStateForPhoto,
  selectFilter,
  setFilterStrength
} from '../main/ets/features/editor/filter/FilterState';
import { FILTER_PRESETS } from '../main/ets/features/editor/filter/FilterCatalog';

export default function filterStateTest() {
  describe('filterStateTest', () => {
    it('starts a new edit session on the original filter', 0, () => {
      const state = createDefaultEditState();
      expect(state.filter.filterId).assertEqual('original');
      expect(state.filter.strength).assertEqual(0);
    });

    it('selects a preset with its default strength', 0, () => {
      const state = selectFilter(createDefaultEditState(), 'heartland');
      expect(state.filter.filterId).assertEqual('heartland');
      expect(state.filter.strength).assertEqual(0.75);
    });

    it('keeps the current filter while changing only strength', 0, () => {
      const selected = selectFilter(createDefaultEditState(), 'dusk_tide');
      const changed = setFilterStrength(selected, 0.42);
      expect(changed.filter.filterId).assertEqual('dusk_tide');
      expect(changed.filter.strength).assertEqual(0.42);
    });

    it('clamps strength at both native boundaries', 0, () => {
      const selected = selectFilter(createDefaultEditState(), 'fieldnote');
      expect(setFilterStrength(selected, -1).filter.strength).assertEqual(0);
      expect(setFilterStrength(selected, 2).filter.strength).assertEqual(1);
    });

    it('ignores an unknown preset without losing the current state', 0, () => {
      const selected = selectFilter(createDefaultEditState(), 'heartland');
      const unchanged = selectFilter(selected, 'missing');
      expect(unchanged.filter.filterId).assertEqual('heartland');
      expect(unchanged.filter.strength).assertEqual(0.75);
    });

    it('resets the filter when a different photo starts editing', 0, () => {
      const selected = selectFilter(createDefaultEditState(), FILTER_PRESETS[2].id);
      const reset = resetEditStateForPhoto();
      expect(selected.filter.filterId).assertEqual('heartland');
      expect(reset.filter.filterId).assertEqual('original');
      expect(reset.filter.strength).assertEqual(0);
    });

    it('registers every newly bundled LUT preset', 0, () => {
      const newIds: string[] = [
        'vel_cinematic_teal',
        'vel_classic_teal_orange',
        'vel_film_fade',
        'vel_golden_cinematic',
        'vel_mono_contrast',
        'vel_moody_blue',
        'vel_sunset_glow',
        'vel_vintage_chrome',
        'vel_vivid_teal',
        'vel_warm_film',
        'vel_warm_pastel',
        'yt_moody_dark'
      ];
      for (const id of newIds) {
        const preset = FILTER_PRESETS.find((item) => item.id === id);
        expect(preset !== undefined).assertTrue();
        expect(preset?.lutPath !== undefined).assertTrue();
      }
    });
  });
}
