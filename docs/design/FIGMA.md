# Figma Visual Mirror

BLab Design System의 **시각 레퍼런스(optional visual mirror)**.
저장소의 `contracts/blab.design.yaml`이 SSOT이고, Figma 파일은
비개발자/디자이너 협업용 downstream mirror다.

- **File**: `Blab Design System` (fileKey `tOz5Wt6IsQyfDL7loNeUw5`)
- **URL**: https://www.figma.com/design/tOz5Wt6IsQyfDL7loNeUw5/Blab-Design-System
- **Status**: Historical BLA-6 Figma Phase 3 completed as of 2026-04-21
  (unrelated to Phases 1–5 in the Astryx adoption plan)

## 페이지 구조

| 페이지 | 역할 |
|--------|------|
| `00. Cover` | 표지 (예약) |
| `01. Foundations` | 토큰/프리미티브 정리 (예약) |
| `02. Primitives` | 기본 원자 (예약) |
| `03. Components` | 조합된 컴포넌트 (현재 채워진 페이지) |

## Variables Collections

| Collection | 변수 수 | 모드 |
|------------|---------|------|
| `BLab/Colors` | 38 | Light 전용 (Figma Free plan은 멀티모드 미지원 — Dark는 `tokens.css` 기반 코드에서 처리) |
| `BLab/Radius` | 6 | xs/sm/md/lg/xl/pill |
| `BLab/Spacing` | 12 | 0~11 (2,4,8,12,16,20,24,32,40,48,64) |

## `03. Components` 페이지 구성

### Navigation 섹션

| 컴포넌트 | Variants | 축 |
|----------|----------|----|
| `BLab/BottomBar` | 12 | ItemCount(3/4/5) × Style(Solid/Glass) × SafeArea(On/Off) |
| `BLab/TabBar` | 18 | TabCount(2/3/4) × SelectedIndex × Divider(On/Off) |

### Feedback 섹션

| 컴포넌트 | Variants | 축 |
|----------|----------|----|
| `BLab/Snackbar` | 8 | Type(Success/Error/Warning/Info) × Action(None/WithAction) |

### Controls 섹션

| 컴포넌트 | Variants | 축 |
|----------|----------|----|
| `BLab/SegmentedControl` | 18 | Size(Small/Medium) × SegmentCount(2/3/4) × SelectedIndex |

### Utility 섹션

| 컴포넌트 | Variants | 축 |
|----------|----------|----|
| `BLab/KeyboardAccessoryBar` | 2 | Layout(Default/WithActions) |
| `BLab/PressableWrapper` | 2 | State(Default/Pressed, scale 0.95) |

## Flutter 원본 매핑

| Figma 컴포넌트 | Flutter 위젯 |
|----------------|--------------|
| `BLab/BottomBar` | `lib/src/widgets/liquid_glass_bottom_bar.dart` |
| `BLab/TabBar` | `lib/src/widgets/liquid_glass_tab_bar.dart` |
| `BLab/Snackbar` | `lib/src/widgets/blab_snackbar.dart` |
| `BLab/SegmentedControl` | `lib/src/widgets/blab_segmented_control.dart` |
| `BLab/KeyboardAccessoryBar` | `lib/src/widgets/keyboard_accessory_bar.dart` |
| `BLab/PressableWrapper` | `lib/src/widgets/pressable_wrapper.dart` |

## 시스템 Audit 결과 (2026-04-21)

`figma_audit_design_system` 기준:

| 항목 | 점수 |
|------|------|
| **Overall Health** | 62/100 (needs-work) |
| Naming & Semantics | 100/100 |
| Consistency | 100/100 |
| Component Metadata | 83/100 |
| Accessibility | 67/100 |
| Token Architecture | 0/100 (Free plan 한계) |
| Coverage | 0/100 (01/02 페이지 아직 비어있음) |

Token Architecture 점수가 0인 건 Free plan에서 멀티모드 불가 탓. 다크 모드는 `tokens.css`와 `lib/src/theme/app_colors.dart`에서 처리한다.

## Typography

Figma 미러는 **Pretendard Variable**을 시각적 의도로 기록하며,
`tokens.css`의 type scale과 1:1로 대응한다:

- BottomBar 탭 라벨: `--blab-tab-size` (10px) / Medium
- TabBar / SegmentedControl 라벨: `--blab-label-size` (13~14px)
- Snackbar 본문: 15px Medium / 액션 15px SemiBold
- KeyboardAccessoryBar "완료": 16px SemiBold

Flutter 패키지는 Pretendard 또는 JetBrains Mono 폰트 파일을 번들하거나
가져오지 않는다. `app_typography.dart`의 `fontFamily` 값은 패밀리 이름
참조일 뿐이며, 소비 제품이 폰트를 제공하지 않으면 Flutter 런타임의
플랫폼 폴백이 적용된다.

`tokens.css`의 CDN 선언은 해당 CSS를 명시적으로 사용하는 브라우저
소비자를 위한 선택적 레퍼런스다. Flutter 또는 Figma에 폰트를
전달하지 않으며, 프로덕션의 self-host, 플랫폼 폴백, 원격 전달 전략은
Design·Legal·Product 결정 전까지 미정이다.

## 유지보수 원칙

1. **SSOT는 `contracts/blab.design.yaml`**. Figma는 미러일 뿐 원본이 아님.
2. 계약과 생성 파이프라인이 검증된 뒤, 별도 권한이 있는 동기화
   작업에서 Figma를 갱신한다.
3. Dark mode는 코드에서만 존재. Figma에는 Light 값만 들어 있음 (Free plan).
4. 신규 컴포넌트 추가 시 **03. Components 페이지**의 해당 Section에 배치.

Phase 1의 `generated/figma-token-mapping.json`은 저장소 안에서만 생성되는
기계 판독용 매핑이다. 이 파일은 Figma API를 호출하거나 위 파일을
변경했다는 증거가 아니며, 원격 동기화·게시 권한도 부여하지 않는다.
