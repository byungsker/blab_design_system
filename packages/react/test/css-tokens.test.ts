import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";

import {
  BLabColors,
  BLabElevation,
  BLabGlass,
  BLabMotion,
  BLabRadii,
  BLabSpacing,
  BLabTypography,
} from "../src/index";

const css = readFileSync(new URL("../src/styles.css", import.meta.url), "utf8");

const cssToken = (name: string) => {
  const match = css.match(new RegExp(`${name}:\\s*([^;]+);`));
  return match?.[1]?.trim();
};

const relativeLuminance = (hex: string) => {
  const channels = [0, 2, 4].map((offset) => Number.parseInt(hex.slice(offset + 1, offset + 3), 16) / 255);
  const linearChannels = channels.map((channel) =>
    channel <= 0.03928 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4,
  );
  const red = linearChannels[0] ?? 0;
  const green = linearChannels[1] ?? 0;
  const blue = linearChannels[2] ?? 0;
  return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
};

const contrastRatio = (foreground: string, background: string) => {
  const foregroundLuminance = relativeLuminance(foreground);
  const backgroundLuminance = relativeLuminance(background);
  const lighter = Math.max(foregroundLuminance, backgroundLuminance);
  const darker = Math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
};

describe("BLab CSS token contract", () => {
  it("keeps representative CSS variables aligned with exported tokens", () => {
    expect(cssToken("--blab-color-primary")).toBe(BLabColors.primary.toLowerCase());
    expect(cssToken("--blab-color-on-primary")).toBe(BLabColors.onPrimary.toLowerCase());
    expect(cssToken("--blab-color-error")).toBe(BLabColors.error.toLowerCase());
    expect(cssToken("--blab-color-on-destructive")).toBe(BLabColors.onError.toLowerCase());
    expect(cssToken("--blab-space-xxl")).toBe(`${BLabSpacing.xxl}px`);
    expect(cssToken("--blab-radius-card")).toBe(`${BLabRadii.card}px`);
    expect(cssToken("--blab-elevation-surface")).toBe(BLabElevation.surface);
    expect(cssToken("--blab-glass-card-blur")).toBe(`${BLabGlass.cardBlur}px`);
    expect(cssToken("--blab-motion-press")).toBe(`${BLabMotion.press}ms`);
    expect(cssToken("--blab-motion-navigation")).toBe(`${BLabMotion.navigation}ms`);
  });

  it("defines semantic component tokens for CSS geometry and type", () => {
    const requiredTokens = [
      "--blab-border-subtle",
      "--blab-color-on-primary",
      "--blab-effect-press-scale",
      "--blab-font-size-body-large",
      "--blab-font-size-body-medium",
      "--blab-font-size-title-medium",
      "--blab-size-touch-target",
      "--blab-space-field-gap",
      "--blab-elevation-segmented",
    ];

    for (const name of requiredTokens) {
      expect(cssToken(name)).toBeDefined();
    }

    expect(cssToken("--blab-font-size-body-large")).toBe(`${BLabTypography.bodyLarge.fontSize}px`);
    expect(cssToken("--blab-line-height-body-large")).toBe(`${BLabTypography.bodyLarge.lineHeight}`);
    expect(cssToken("--blab-font-size-body-medium")).toBe(`${BLabTypography.bodyMedium.fontSize}px`);
    expect(cssToken("--blab-line-height-body-medium")).toBe(`${BLabTypography.bodyMedium.lineHeight}`);
    expect(cssToken("--blab-font-size-title-medium")).toBe(`${BLabTypography.titleMedium.fontSize}px`);
  });

  it("keeps action foreground tokens at WCAG AA normal-text contrast", () => {
    expect(contrastRatio(BLabColors.onPrimary, BLabColors.primary)).toBeGreaterThanOrEqual(4.5);
    expect(contrastRatio(BLabColors.onError, BLabColors.error)).toBeGreaterThanOrEqual(4.5);
  });
});
