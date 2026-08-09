<!-- GENERATED CODE - DO NOT EDIT. -->
# BLDS state and accessibility contract

State truth is sourced from `contracts/components/state-applicability.yaml` and its generated evidence mirror.

## Sources

- `contracts/components/agent-registry.yaml` — `1939e15dba6875a4a7aa2ed2b31c07dcfe4d9b155450b24455f10319281c6cfc`
- `contracts/components/state-applicability.yaml` — `1aabd860a7422f9cac6e825088e796cf329d92f34114dec308f8a8c12ac0648f`
- `generated/component-state-coverage.yaml` — `0fda4cb18f97d88158c83e82e78033a8b8851e0454104eb5307b6e3cef2a6466`
- `contracts/tokens/blab.tokens.yaml` — `a94701b1191e3daa8dee88177d3523ce9c8ae8b5f56f5efdf0016f053d634dbe`
- `contracts/components/figma-agent-mapping.yaml` — `99b584442387369163a3ddb346cd407f6023ae0a0ad61d52a1d10d743536a7d8`

## BLabButton

- Required: `default`, `hover-pointer`, `pressed`, `focus`, `disabled`, `destructive-variant`
- Conditional: `loading-busy`
- Not applicable: `selected`, `current`, `invalid`, `expanded`

## BLabTextField

- Required: `empty`, `populated`, `hover-pointer`, `focus`, `read-only`, `obscured`, `multiline`
- Conditional: `disabled`, `required`, `invalid`, `error-help`, `clear-action`
- Not applicable: `selected`, `loading`, `current`

## BLabSegmentedControl

- Required: `unselected`, `selected`, `hover-pointer`, `pressed`, `keyboard-visible-focus`, `controlled-selection`
- Conditional: `disabled-item-or-control`, `scrollable-overflow`
- Not applicable: `loading`, `busy`, `invalid`, `error`, `overlay`, `expanded`, `current`, `disclosure`, `drag`, `haptic`

## BLabTabBar

- Required: `unselected`, `selected-current`, `hover-pointer`, `pressed`, `keyboard-visible-focus`, `controller-controlled-selection`, `keyboard-roving-focus`
- Conditional: `scrollable-overflow-when-isScrollable`
- Not applicable: `disabled`, `loading`, `busy`, `invalid`, `error`, `expanded`, `disclosure`, `drag-selection`, `haptic`, `bottom-bar`

## BLabBottomBar

- Required: `unselected`, `selected-current`, `hover-pointer`, `pressed`, `focus`, `long-press-drag`
- Conditional: `optional-action-with-callback-and-localized-label`, `expanded-with-callback-localized-label-and-controlled-state`
- Not applicable: `disabled`, `loading`, `invalid`

## BLabPressableWrapper

- Required: `default`, `pressed`, `focus`, `long-press-when-supplied`
- Conditional: `hover-pointer`
- Not applicable: `selected`, `busy`, `invalid`

## BLabCard

- Required: `static-default`
- Conditional: `interactive-hover-when-actionable`, `interactive-pressed-when-actionable`, `interactive-focus-when-actionable`, `long-press`, `role-determined-by-action`
- Not applicable: `loading`, `selected`, `disabled`

## BLabSnackbar

- Required: `entering`, `visible`, `exiting`, `success`, `error`, `warning`, `info`, `live-announcement`
- Conditional: `action`, `dismiss`, `hover-pointer`, `pressed`, `keyboard-visible-focus`, `timer-paused`, `programmatic-close`
- Not applicable: `disabled`, `loading`, `selected`, `invalid`, `current`, `expanded`

## BLabKeyboardAccessoryBar

- Required: `default`, `hover-pointer`, `pressed`, `focus`, `disabled-per-action`
- Conditional: `repeated-action-active-for-undo-redo`, `scrollable-overflow`
- Not applicable: `loading`, `selected`, `invalid`
