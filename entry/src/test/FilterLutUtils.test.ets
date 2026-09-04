import { describe, it, expect } from '@ohos/hypium';
import { decodeLutAscii } from '../main/ets/features/editor/filter/FilterLutUtils';

export default function filterLutUtilsTest() {
  describe('filterLutUtilsTest', () => {
    it('decodes standard ASCII LUT header correctly', 0, () => {
      const text = 'TITLE "Fieldnote LUT"\nLUT_3D_SIZE 33\n0.0 0.0 0.0\n';
      const bytes = new Uint8Array(Array.from(text).map((c: string) => c.charCodeAt(0)));
      const decoded = decodeLutAscii(bytes);
      expect(decoded).assertEqual(text);
    });

    it('handles empty input gracefully', 0, () => {
      const bytes = new Uint8Array(0);
      const decoded = decodeLutAscii(bytes);
      expect(decoded).assertEqual('');
    });

    it('decodes UTF-8 comments without character corruption', 0, () => {
      // UTF-8 encoded "测试滤镜 123"
      const text = 'TITLE "测试滤镜 123"\n';
      const utf8Bytes: number[] = [];
      for (let i = 0; i < text.length; i++) {
        const code = text.charCodeAt(i);
        if (code < 0x80) {
          utf8Bytes.push(code);
        } else {
          // UTF-8 3-byte encoding for BMP Chinese chars
          utf8Bytes.push(0xe0 | ((code >> 12) & 0x0f));
          utf8Bytes.push(0x80 | ((code >> 6) & 0x3f));
          utf8Bytes.push(0x80 | (code & 0x3f));
        }
      }
      const bytes = new Uint8Array(utf8Bytes);
      const decoded = decodeLutAscii(bytes);
      expect(decoded).assertEqual(text);
    });

    it('decodes large chunked buffer accurately and rapidly', 0, () => {
      const line = '0.123456 0.234567 0.345678\n';
      const repeatCount = 2000; // ~54 KB
      let expected = '';
      for (let i = 0; i < repeatCount; i++) {
        expected += line;
      }
      const bytes = new Uint8Array(Array.from(expected).map((c: string) => c.charCodeAt(0)));
      const decoded = decodeLutAscii(bytes);
      expect(decoded.length).assertEqual(expected.length);
      expect(decoded.slice(0, 100)).assertEqual(expected.slice(0, 100));
      expect(decoded.slice(-100)).assertEqual(expected.slice(-100));
    });
  });
}
