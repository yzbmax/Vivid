# Import Preview and Filter Debugging Plan

**Goal:** Restore a reliable imported-photo preview and make every LUT preset render its own observable result without masking failures.

## Task 1: Establish the failure boundaries

- Trace picker result -> route parameter -> sandbox copy -> PixelMap decode -> preview display.
- Trace LUT asset -> CUBE parser -> native registry -> PixelMap render -> thumbnail/main preview.
- Run the existing native parser/renderer tests and add focused diagnostics for all ten bundled LUTs.
- Record the exact failing boundary before changing production code.

## Task 2: Add regression coverage

- Add a test for the confirmed import/copy failure mode that can be exercised without a device.
- Add native tests proving all ten LUTs parse, differ from identity for representative colors, and differ from one another where expected.
- Add a regression check preventing failed filter thumbnails from silently displaying the same source image as if rendering succeeded.

## Task 3: Implement the smallest fixes

- Preserve a displayable picker URI while materializing a separately validated local source for image processing.
- Make file copying handle partial writes and preserve/validate the selected asset format.
- Propagate actionable import/decode errors instead of silently blanking the editor.
- Isolate per-filter load/render failures and stop presenting the common source image as a rendered thumbnail.
- Fix the native LUT/parser/renderer boundary only if the tests demonstrate a defect there.

## Task 4: Verify

- Run focused native and ArkTS checks first.
- Run the HarmonyOS debug build because the change crosses picker, image decoding, ArkTS/native bridge, and C++.
- Inspect the final diff for unrelated edits and report device-only checks that remain unverified.
