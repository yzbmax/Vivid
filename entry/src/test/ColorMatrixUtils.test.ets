import { describe, it, expect } from '@ohos/hypium';
import { buildAdjustmentFilter, multiplyColorMatrices } from '../main/ets/utils/ColorMatrixUtils';

export default function colorMatrixUtilsTest() {
  describe('ColorMatrixUtilsTest', () => {

    it('returns identity matrix when all parameters are 0', 0, () => {
      const matrix = buildAdjustmentFilter(0, 0, 0, 0, 0);
      const identity = [
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0
      ];
      expect(matrix.length).assertEqual(20);
      for (let i = 0; i < 20; i++) {
        expect(Math.abs(matrix[i] - identity[i]) < 1e-6).assertTrue();
      }
    });

    it('produces normalized brightness offset without blowout', 0, () => {
      // Step 1: Small adjustment (brightness = 1) must have tiny offset < 0.01 (not 0.8 which turns screen white)
      const matrixSmall = buildAdjustmentFilter(0, 0, 0, 0, 1);
      expect(matrixSmall[4] > 0).assertTrue();
      expect(matrixSmall[4] < 0.01).assertTrue();
      expect(matrixSmall[9] < 0.01).assertTrue();
      expect(matrixSmall[14] < 0.01).assertTrue();

      // Step 2: Max adjustment (brightness = 100) must stay within normalized range <= 0.35
      const matrixMax = buildAdjustmentFilter(0, 0, 0, 0, 100);
      expect(matrixMax[4] <= 0.35).assertTrue();
      expect(matrixMax[4] >= 0.20).assertTrue();

      // Step 3: Min adjustment (brightness = -100) must stay within normalized range >= -0.35
      const matrixMin = buildAdjustmentFilter(0, 0, 0, 0, -100);
      expect(matrixMin[4] >= -0.35).assertTrue();
      expect(matrixMin[4] <= -0.20).assertTrue();
    });

    it('produces normalized contrast offset anchored around midtone', 0, () => {
      // contrast = 20: factor = 1.2, offset must be approx -0.1 (not -25.6!)
      const matrix = buildAdjustmentFilter(0, 20, 0, 0, 0);
      expect(Math.abs(matrix[0] - 1.2) < 1e-6).assertTrue();
      // Midtone 0.5: 0.5 * 1.2 + offset = 0.5 => offset must be -0.1
      expect(Math.abs(matrix[4] - (-0.1)) < 1e-4).assertTrue();
      expect(Math.abs(matrix[9] - (-0.1)) < 1e-4).assertTrue();
      expect(Math.abs(matrix[14] - (-0.1)) < 1e-4).assertTrue();
    });

    it('produces normalized warmth offset without channel blowout', 0, () => {
      // warmth = 50: red offset and blue offset must be subtle (< 0.15, not 42.5!)
      const matrix = buildAdjustmentFilter(0, 0, 0, 50, 0);
      expect(matrix[4] > 0).assertTrue();
      expect(matrix[4] < 0.15).assertTrue();
      expect(matrix[14] < 0).assertTrue();
      expect(matrix[14] > -0.15).assertTrue();
      // Green channel offset is 0
      expect(Math.abs(matrix[9]) < 1e-6).assertTrue();
    });

    it('exposure and saturation scale channels cleanly without offset drift', 0, () => {
      const matrixExp = buildAdjustmentFilter(50, 0, 0, 0, 0);
      expect(Math.abs(matrixExp[0] - 1.5) < 1e-6).assertTrue();
      expect(Math.abs(matrixExp[4]) < 1e-6).assertTrue();

      const matrixSat = buildAdjustmentFilter(0, 0, 50, 0, 0);
      expect(Math.abs(matrixSat[4]) < 1e-6).assertTrue();
      expect(Math.abs(matrixSat[9]) < 1e-6).assertTrue();
      expect(Math.abs(matrixSat[14]) < 1e-6).assertTrue();
    });

    it('keeps all offsets bounded when all sliders are combined at extremes', 0, () => {
      const combined = buildAdjustmentFilter(50, 50, 50, 50, 50);
      // All offsets must be within reasonable [-1.0, 1.0] range
      expect(Math.abs(combined[4]) <= 1.0).assertTrue();
      expect(Math.abs(combined[9]) <= 1.0).assertTrue();
      expect(Math.abs(combined[14]) <= 1.0).assertTrue();
      // Alpha row unchanged
      expect(combined[15]).assertEqual(0);
      expect(combined[16]).assertEqual(0);
      expect(combined[17]).assertEqual(0);
      expect(combined[18]).assertEqual(1);
      expect(combined[19]).assertEqual(0);
    });
  });
}
