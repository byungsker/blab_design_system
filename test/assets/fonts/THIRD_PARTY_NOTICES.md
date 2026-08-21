# Phase 4 test-font third-party notices

These files are deterministic Flutter-test fixtures only. They are not declared
in `pubspec.yaml`, are not packaged as BLDS runtime assets, do not establish the
production Pretendard policy, and do not establish typography, localization,
visual, or accessibility conformance.

The golden harness registers the Noto text fixture selected for each isolated
test process under a process-local `Pretendard` alias because current public
widgets explicitly request that family. This alias is only a test mechanism;
the Noto files are not Pretendard.

## Noto Sans KR

- File: `NotoSansKR[wght].ttf`
- Purpose: deterministic Latin and Korean fixture text
- Repository: `https://github.com/google/fonts`
- Pinned commit: `7ff85c87f93ea6cca5f41c69f2e4edcb90240f26`
- Exact source:
  `https://raw.githubusercontent.com/google/fonts/7ff85c87f93ea6cca5f41c69f2e4edcb90240f26/ofl/notosanskr/NotoSansKR%5Bwght%5D.ttf`
- SHA-256:
  `194018e6b2b293a7964f037b25c0249ce1418bc9ab3c971060a03aa57861e252`
- License: SIL Open Font License 1.1
- License copy: `LICENSE-NOTO-SANS-KR.txt`
- License SHA-256:
  `1c05c68c34f9708415aada51f17e1b0092d2cea709bf4a94cd38114f9e73d7d9`

## Noto Sans Arabic

- File: `NotoSansArabic[wdth,wght].ttf`
- Purpose: deterministic Arabic RTL and mixed bidi fixture text
- Repository: `https://github.com/google/fonts`
- Pinned commit: `7ff85c87f93ea6cca5f41c69f2e4edcb90240f26`
- Exact source:
  `https://raw.githubusercontent.com/google/fonts/7ff85c87f93ea6cca5f41c69f2e4edcb90240f26/ofl/notosansarabic/NotoSansArabic%5Bwdth,wght%5D.ttf`
- SHA-256:
  `63111b5b2e074dd48cc67692e0a2726d86ee94c1c37fe8598257b7b4e87e869e`
- License: SIL Open Font License 1.1
- License copy: `LICENSE-NOTO-SANS-ARABIC.txt`
- License SHA-256:
  `07fc70bfeb985cc1a87a8587d0a0c80bab11c86c9dc3fd95b6f0cb332f983e96`

## Material Icons

- File: `MaterialIcons-Regular.otf`
- Purpose: deterministic Material icon glyphs in candidate captures
- Flutter toolchain artifact revision:
  `3012db47f3130e62f7cc0beabff968a33cbec8d8`
- Exact archive:
  `https://storage.googleapis.com/flutter_infra_release/flutter/fonts/3012db47f3130e62f7cc0beabff968a33cbec8d8/fonts.zip`
- Archive SHA-256:
  `e56fa8e9bb4589fde964be3de451f3e5b251e4a1eafb1dc98d94add034dd5a86`
- Font SHA-256:
  `d9865b671a09d683d13a863089d8825e0f61a37696ce5d7d448bc8023aa62453`
- License: Creative Commons Attribution 4.0 International
- License copy: `LICENSE-MATERIAL-ICONS.txt`
- License SHA-256:
  `be698262aecd042c0de6f886cc0af622f8def446462026992cc530275d8a9e74`

## Cupertino Icons

- File: `CupertinoIcons.ttf`
- Purpose: deterministic Cupertino icon glyphs in candidate captures
- Repository: `https://github.com/flutter/packages`
- Pinned commit/tag target:
  `701d60a08941da4c6c5633af5263881963ed07b3`
  (`cupertino_icons-v1.0.8`)
- Exact source:
  `https://raw.githubusercontent.com/flutter/packages/701d60a08941da4c6c5633af5263881963ed07b3/third_party/packages/cupertino_icons/assets/CupertinoIcons.ttf`
- SHA-256:
  `67c44fe9183b002e79dde7f6977e2988661c9a3e4a3c5fce968787efdbed823c`
- License: MIT
- License copy: `LICENSE-CUPERTINO-ICONS.txt`
- License SHA-256:
  `310d6ab6483280280c9db122bded0a63c09558bc5743720f61dbcbb494db370a`
