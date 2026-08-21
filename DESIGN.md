---
version: alpha
name: BLab
description: |
  Calm, polished, trustworthy — a Liquid Glass design language for modern products.
  Interfaces feel deliberate, smooth, and lightweight through translucent pill-shaped
  surfaces, heavy backdrop blur, hairline borders, and an inner top-edge highlight
  that reads as refracted light.

colors:
  # Brand
  primary: "#5B7FFF"
  primary-light: "#6B8AFF"

  # Status
  success: "#10B981"
  success-alt: "#34C759"
  success-bg: "#D1FAE5"
  error: "#FF3B30"
  error-alt: "#EF4444"
  error-bg: "#FEE2E2"
  warning: "#FF9500"
  warning-alt: "#FFBE0B"
  info: "#4ECDC4"
  info-alt: "#3498DB"
  destructive: "#FF6B6B"

  # Light Surfaces
  scaffold-light: "#FAFAFA"
  surface-light: "#FFFFFF"
  card-light: "#FFFFFF"
  elevated-light: "#F8F9FA"
  subtle-blue-light: "#F5F7FF"

  # Dark Surfaces
  scaffold-dark: "#121212"
  surface-dark: "#1E1E1E"
  card-dark: "#1E1E1E"
  elevated-dark: "#2C2C2E"
  subtle-dark: "#2A2A2A"

  # Greys
  grey-50: "#F5F5F5"
  grey-100: "#F3F4F6"
  grey-200: "#E5E7EB"
  grey-300: "#D1D5DB"
  grey-400: "#9CA3AF"
  grey-500: "#6B7280"
  grey-600: "#4B5563"
  grey-700: "#374151"
  grey-800: "#1F2937"
  grey-900: "#111827"

  # Chart Ramp (use sparingly)
  chart-1: "#5B7FFF"
  chart-2: "#FF6B6B"
  chart-3: "#4ECDC4"
  chart-4: "#FFBE0B"
  chart-5: "#9B59B6"
  chart-6: "#3498DB"
  chart-7: "#E74C3C"
  chart-8: "#1ABC9C"
  chart-9: "#F39C12"
  chart-10: "#8E44AD"

typography:
  display:
    fontFamily: Pretendard Variable
    fontSize: 44px
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: -0.022em
  h1:
    fontFamily: Pretendard Variable
    fontSize: 32px
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: -0.02em
  h2:
    fontFamily: Pretendard Variable
    fontSize: 24px
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: -0.015em
  title:
    fontFamily: Pretendard Variable
    fontSize: 20px
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: -0.01em
  subtitle:
    fontFamily: Pretendard Variable
    fontSize: 17px
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: -0.005em
  body:
    fontFamily: Pretendard Variable
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
  body-strong:
    fontFamily: Pretendard Variable
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.5
  caption:
    fontFamily: Pretendard Variable
    fontSize: 13px
    fontWeight: 500
    lineHeight: 1.45
  label:
    fontFamily: Pretendard Variable
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1.4
  button:
    fontFamily: Pretendard Variable
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: -0.005em
  tab:
    fontFamily: Pretendard Variable
    fontSize: 10px
    fontWeight: 600
    lineHeight: 1.2
  code:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5

spacing:
  xs: 2px
  sm: 8px
  md: 16px
  lg: 20px
  xl: 24px
  xxl: 32px

rounded:
  xs: 6px
  sm: 10px
  md: 12px
  lg: 16px
  xl: 20px
  pill: 100px

components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#FFFFFF"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    height: 52px
    padding: 0 24px

  button-primary-hover:
    backgroundColor: "{colors.primary-light}"

  button-secondary:
    backgroundColor: "rgba(0,0,0,0.08)"
    textColor: "#000000"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    height: 52px
    padding: 0 24px

  button-secondary-dark:
    backgroundColor: "rgba(255,255,255,0.12)"
    textColor: "#FFFFFF"

  button-destructive:
    backgroundColor: "{colors.error}"
    textColor: "#FFFFFF"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    height: 52px
    padding: 0 24px

  card-standard:
    backgroundColor: "rgba(0,0,0,0.08)"
    textColor: "#000000"
    rounded: "{rounded.lg}"
    padding: 20px

  card-standard-dark:
    backgroundColor: "rgba(255,255,255,0.12)"
    textColor: "#FFFFFF"

  card-elevated:
    backgroundColor: "rgba(0,0,0,0.08)"
    textColor: "#000000"
    rounded: "{rounded.xl}"
    padding: 20px

  card-elevated-dark:
    backgroundColor: "rgba(255,255,255,0.12)"
    textColor: "#FFFFFF"

  input-field:
    backgroundColor: "{colors.grey-100}"
    textColor: "#000000"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: 16px
    height: 52px

  input-field-dark:
    backgroundColor: "{colors.elevated-dark}"
    textColor: "#FFFFFF"

  bottom-bar:
    backgroundColor: "rgba(0,0,0,0.08)"
    textColor: "#000000"
    rounded: "{rounded.pill}"
    padding: 8px

  bottom-bar-dark:
    backgroundColor: "rgba(255,255,255,0.12)"
    textColor: "#FFFFFF"

  snackbar-success:
    backgroundColor: "{colors.success-bg}"
    textColor: "{colors.success}"
    rounded: "{rounded.lg}"
    padding: 16px

  snackbar-error:
    backgroundColor: "{colors.error-bg}"
    textColor: "{colors.error}"
    rounded: "{rounded.lg}"
    padding: 16px

  segmented-control:
    backgroundColor: "rgba(0,0,0,0.08)"
    textColor: "#000000"
    rounded: "{rounded.sm}"
    padding: 2px

  segmented-control-dark:
    backgroundColor: "rgba(255,255,255,0.12)"
    textColor: "#FFFFFF"

  segmented-control-selected:
    backgroundColor: "{colors.surface-light}"
    textColor: "#000000"
    rounded: "{rounded.sm}"
    padding: 2px

  segmented-control-selected-dark:
    backgroundColor: "{colors.surface-dark}"
    textColor: "#FFFFFF"
---

## Overview

BLab is a calm, polished, and trustworthy design system built around **Liquid Glass** — translucent pill-shaped surfaces that float over content with heavy backdrop blur, a hairline border, and an inner top-edge highlight that reads as refracted light.

The visual identity is intentionally restrained: interfaces should feel deliberate, smooth, and lightweight — never noisy, never decorative, never dense without hierarchy. BLab communicates clarity before excitement. Surfaces feel stable, readable, and refined. Visual style supports confidence and ease of use.

Both light and dark modes are first-class citizens. Dark mode should feel calm and premium, not neon-heavy or overly dramatic. The emotional tone is preserved across themes.

The design system ships as a Flutter UI component library and a CSS token sheet. The single source of truth is the `blab-design` skill bundle, which distributes tokens, a JSX reference UI kit, Pretendard fonts, and brand/a11y/motion docs.

## Colors

The palette is built on a high-contrast neutral foundation with a single periwinkle blue accent. Color is used semantically rather than decoratively.

- **Primary (#5B7FFF):** The brand accent — a calm, trustworthy periwinkle blue. Used sparingly for primary CTAs, active states, and focus rings. The hover variant (#6B8AFF) is slightly lighter.
- **Success (#10B981):** Positive feedback, completion states. An alternative brighter green (#34C759) is available for iOS-native contexts.
- **Error (#FF3B30):** Destructive actions, validation failures. An alternative red (#EF4444) aligns with Material conventions.
- **Warning (#FF9500):** Cautionary states without alarm.
- **Info (#4ECDC4):** Neutral informational states.
- **Destructive (#FF6B6B):** A softer red for non-critical destructive actions.

### Surfaces

Light mode backgrounds range from pure white (#FFFFFF) for cards to off-white (#FAFAFA) for scaffolds. Dark mode inverts to deep charcoal (#121212) scaffolds and near-black (#1E1E1E) surfaces. Elevation is communicated through subtle tonal shifts rather than heavy shadows.

### Text Hierarchy

Text opacity drives hierarchy rather than grey values. On light surfaces, black is used at varying opacities. On dark surfaces, white is used at the same opacity steps:
- **Primary:** 100% opacity — headlines, body copy
- **Secondary:** 87% opacity — subtitles, secondary labels
- **Tertiary:** 60% opacity — captions, placeholders, disabled states
- **Quaternary:** 38% opacity — hints, disabled icons
- **Inverse:** Pure white or black — text on primary/destructive surfaces

### Borders

All borders are hairline-thin (0.5px for glass surfaces, 1px for inputs). Opacity scales with intent:
- **Subtle:** 5% light / 8% dark — dividers, separators
- **Default:** 8% light / 15% dark — card outlines, input borders
- **Strong:** 15% light / 22% dark — focused states, emphasized boundaries

### Liquid Glass Surfaces

BLab's signature effect uses translucent fills with backdrop blur:
- **Blur:** 25px radius
- **Saturation:** 180%
- **Light Fill:** rgba(0,0,0,0.08)
- **Light Border:** rgba(0,0,0,0.08) at 0.5px
- **Light Highlight:** rgba(255,255,255,0.60) as a top-edge gradient fading to transparent at ~45%
- **Dark Fill:** rgba(255,255,255,0.12)
- **Dark Border:** rgba(255,255,255,0.15) at 0.5px
- **Dark Highlight:** rgba(255,255,255,0.15) as a top-edge gradient fading to transparent at ~45%

## Typography

BLab uses **Pretendard Variable** as its primary typeface — a Korean-Latin hybrid that feels Apple-SD-Gothic-adjacent. It ships via CDN in web contexts and falls back to system defaults (SF Pro, Apple SD Gothic Neo, system-ui) in Flutter until self-hosted. **JetBrains Mono** handles code and numeric displays.

The type scale is tight and confident, with negative letter-spacing on larger sizes to feel contemporary and premium:

- **Display (44px / 700 / -0.022em):** Hero moments, large numerals, welcome screens. Line height is intentionally tight at 1.1.
- **H1 (32px / 700 / -0.02em):** Page titles, top-level headings.
- **H2 (24px / 700 / -0.015em):** Section titles, card headers.
- **Title (20px / 600 / -0.01em):** Component titles, dialog headers.
- **Subtitle (17px / 600 / -0.005em):** List item titles, iOS-native feeling labels.
- **Body (16px / 400 / 0):** Primary reading text. Generous 1.5 line height for readability.
- **Body Strong (16px / 600 / 0):** Emphasized body text without a size jump.
- **Caption (13px / 500 / 0):** Supplemental text, timestamps, metadata. Rendered at 60% opacity by default.
- **Label (14px / 500 / 0):** Form labels, chip text, badge content.
- **Button (16px / 600 / -0.005em):** CTA labels. Slightly tighter line height (1.2) for vertical centering.
- **Tab (10px / 600 / 0):** Bottom navigation labels. Small but bold for legibility at scale.
- **Code (14px / 400 / 0):** Inline code, numeric displays, monospace data.

## Layout & Spacing

The spacing system uses a 4px base grid. All spacing values are multiples of 4px, with 2px as the tightest unit for hairline adjustments.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 2px | Hairline gaps, icon-text separation |
| sm | 8px | Tight grouping, inner padding |
| md | 16px | Default padding, card gutters |
| lg | 20px | Card internal padding, section separation |
| xl | 24px | Screen edge padding, modal insets |
| xxl | 32px | Large section breaks, hero spacing |

The layout philosophy favors breathable spacing over cramped density. Related elements are grouped through proximity; unrelated elements are separated generously. Never compress layouts until hierarchy disappears.

## Elevation & Depth

BLab does not use traditional Material elevation with cast shadows as its primary depth signal. Instead, depth is achieved through the **Glass Stack** — a layered translucent system:

- **Level 0 (Scaffold):** The base background (#FAFAFA light, #121212 dark).
- **Level 1 (Standard Card):** `backdrop-filter: blur(25px)`, `background: rgba(0,0,0,0.08)` (light) or `rgba(255,255,255,0.12)` (dark), with a 0.5px hairline border.
- **Level 2 (Elevated/Modal):** Same blur, higher opacity fill, plus a soft diffused shadow.

Every glass surface features an inner top-edge highlight gradient — from white at 60% opacity (light) or 15% opacity (dark) fading to transparent at ~45% — simulating refracted light passing through the surface.

Shadows are used sparingly and are extremely soft:
- **Level 1:** `0 1px 4px rgba(0,0,0,0.08)` light, `0 1px 4px rgba(0,0,0,0.35)` dark — segmented controls, chips
- **Level 2:** `0 4px 12px rgba(0,0,0,0.10)` light, `0 4px 12px rgba(0,0,0,0.40)` dark — card hover, dropdowns
- **Level 3:** `0 8px 24px rgba(0,0,0,0.12)` light, `0 8px 24px rgba(0,0,0,0.50)` dark — modals, sheets
- **Float:** `0 8px 32px rgba(0,0,0,0.15)` light, `0 8px 32px rgba(0,0,0,0.55)` dark — bottom bars, floating action bars, keyboard accessories

In dark mode, shadows become significantly stronger to maintain visible separation against dark surfaces.

## Shapes

The shape language is soft, approachable, and consistently rounded. There are no sharp corners in the base system.

- **xs (6px):** Future use, smallest interactive elements.
- **sm (10px):** Segmented controls (outer), small chips, compact badges.
- **md (12px):** Buttons, text inputs, small cards. The workhorse radius.
- **lg (16px):** Cards, snackbars, medium surfaces. Default card radius.
- **xl (20px):** Large cards, hero containers, modals.
- **pill (100px):** Bottom bars, tab bars, floating action bars, keyboard accessory bars, keyboard keys. Fully rounded caps create a tactile, approachable feel.

## Components

### Buttons

Buttons express hierarchy through background treatment, not size variation.

- **Primary:** Solid primary blue (#5B7FFF) with white text. Full-width by default with 52px height. Used for the single most important action on a screen.
- **Secondary:** Liquid glass fill (rgba(0,0,0,0.08) light, rgba(255,255,255,0.12) dark) with hairline border. Black text (light) or white text (dark). Used for secondary actions that still need visibility.
- **Destructive:** Solid error red (#FF3B30) with white text. Reserved for irreversible actions.

All buttons use the `md` (12px) radius, 16px font size with 600 weight, and 52px minimum height. Full-width buttons have 24px horizontal padding.

### Cards

The signature BLabCard is a Liquid Glass container:
- `backdrop-filter: blur(25px)`
- Fill: `rgba(0,0,0,0.08)` (light) or `rgba(255,255,255,0.12)` (dark)
- Border: 0.5px solid `rgba(0,0,0,0.08)` (light) or `rgba(255,255,255,0.15)` (dark)
- Radius: 16px (`lg`)
- Padding: 20px (`lg`)
- Optional inner highlight gradient on the top edge

Cards can be made tappable with a press-scale animation (150ms) and haptic feedback.

### Text Fields

Inputs prioritize readability and focus clarity:
- Background: #F3F4F6 (light) or #2C2C2E (dark)
- Radius: 12px (`md`)
- Padding: 16px horizontal, 16px vertical
- Border: none in rest state; 2px solid primary in focus; 1px solid error in invalid state
- Typography: 16px body weight

### Bottom Bar

A pill-shaped floating navigation bar:
- Radius: 100px (`pill`)
- Fill: glass with 25px blur
- Shadow: float level
- Contains 3-5 tab items with 10px bold labels and optional icons
- Features a "droplet" indicator that slides between active tabs (300ms ease)

### Segmented Control

A compact pill-shaped picker:
- Outer radius: 10px (`sm`)
- Inner padding: 2px (`xs`)
- Background: glass fill
- Selected segment: solid surface (#FFFFFF or #1E1E1E) with Level 1 shadow
- Selection slide animation: 180ms

### Snackbars

Floating toasts with semantic color coding:
- Success: mint background (#D1FAE5) with green text (#10B981)
- Error: rose background (#FEE2E2) with red text (#FF3B30)
- Warning and info variants use the same pattern
- Radius: 16px (`lg`)
- Appear with a gentle slide + fade (300ms)

## Do's and Don'ts

### Do
- Use semantic tokens before raw values.
- Reuse existing component patterns before creating new ones.
- Keep hierarchy clear and restrained — only the most important action should carry the strongest emphasis.
- Use depth and glass effects intentionally, not decoratively.
- Prioritize readability, accessibility, and consistency.
- Respect reduced motion preferences — when motion is reduced, preserve clarity through opacity and state change.

### Don't
- Do not introduce arbitrary colors, spacing, radius, or elevation values.
- Do not overuse blur, glow, or glass effects. Liquid Glass is a seasoning, not the main dish.
- Do not make every action visually loud. Most actions should be calm.
- Do not rely on animation to create meaning or compensate for weak hierarchy.
- Do not trade clarity for novelty.
- Do not hide or weaken focus rings, readability, or touch targets for stylistic reasons.
- Do not assign colors only for visual variety — every color must have a semantic role.
- Do not compress layouts until hierarchy disappears.
- Do not depend on excessive borders for every separation — spacing and surface relationships should do the work.
- Do not create alarming visual feedback for low-severity states.
- Do not let motion slow down core tasks.
- Do not sacrifice 4.5:1 contrast ratios for visual flair.
