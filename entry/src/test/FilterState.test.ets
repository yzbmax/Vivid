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

    // ──────── Vivid 0.1.9：8 款新增 LUT（实施计划 §2.1 / 任务 4）────────

    it('registers the 8 new Vivid 0.1.9 LUT presets with expected metadata', 0, () => {
      interface ExpectEntry {
        id: string;
        name: string;
        defaultStrength: number;
        lutPath: string;
      }
      const expected: ExpectEntry[] = [
        { id: 'jade_mist',       name: '玉烟', defaultStrength: 0.68, lutPath: 'filters/JadeMist.cube' },
        { id: 'cinnabar_glow',   name: '丹霞', defaultStrength: 0.65, lutPath: 'filters/CinnabarGlow.cube' },
        { id: 'ink_noir',        name: '墨影', defaultStrength: 0.80, lutPath: 'filters/InkNoir.cube' },
        { id: 'rice_paper',      name: '宣纸', defaultStrength: 0.62, lutPath: 'filters/RicePaper.cube' },
        { id: 'tea_film',        name: '茶褐', defaultStrength: 0.72, lutPath: 'filters/TeaFilm.cube' },
        { id: 'celadon_cool',    name: '青瓷', defaultStrength: 0.70, lutPath: 'filters/CeladonCool.cube' },
        { id: 'amber_hour',      name: '琥珀', defaultStrength: 0.66, lutPath: 'filters/AmberHour.cube' },
        { id: 'moonlit_blue',    name: '月青', defaultStrength: 0.74, lutPath: 'filters/MoonlitBlue.cube' }
      ];
      for (const entry of expected) {
        const preset = FILTER_PRESETS.find((item) => item.id === entry.id);
        expect(preset !== undefined).assertTrue();
        expect(preset?.name).assertEqual(entry.name);
        expect(preset?.defaultStrength).assertEqual(entry.defaultStrength);
        expect(preset?.lutPath).assertEqual(entry.lutPath);
        expect(preset?.version).assertEqual(1);
      }
    });

    it('preserves the original preset order (original first, new 0.1.9 appended at tail)', 0, () => {
      expect(FILTER_PRESETS[0].id).assertEqual('original');
      // 原有 22 个 LUT 的顺序不能被打乱
      expect(FILTER_PRESETS[1].id).assertEqual('fieldnote');
      expect(FILTER_PRESETS[22].id).assertEqual('yt_moody_dark');
      // 8 款 Vivid 0.1.9 新滤镜追加在索引 23..30
      expect(FILTER_PRESETS[23].id).assertEqual('jade_mist');
      expect(FILTER_PRESETS[30].id).assertEqual('moonlit_blue');
      expect(FILTER_PRESETS.length).assertEqual(31); // 1 original + 22 旧 LUT + 8 新 LUT
    });

    it('keeps every LUT lutPath unique (no cache key collisions across presets)', 0, () => {
      const paths: string[] = [];
      for (const preset of FILTER_PRESETS) {
        if (preset.lutPath !== undefined) {
          const dup = paths.find((p) => p === preset.lutPath);
          expect(dup === undefined).assertTrue();
          paths.push(preset.lutPath);
        }
      }
    });

    it('selects a Vivid 0.1.9 preset with its own default strength', 0, () => {
      const selected = selectFilter(createDefaultEditState(), 'jade_mist');
      expect(selected.filter.filterId).assertEqual('jade_mist');
      expect(selected.filter.strength).assertEqual(0.68);
      const moon = selectFilter(createDefaultEditState(), 'moonlit_blue');
      expect(moon.filter.strength).assertEqual(0.74);
    });

    it('ensures all filter presets have Chinese names', 0, () => {
      const chineseRegex = /^[\u4e00-\u9fa5]+$/;
      for (const preset of FILTER_PRESETS) {
        expect(chineseRegex.test(preset.name)).assertTrue();
      }
    });
  });
}
