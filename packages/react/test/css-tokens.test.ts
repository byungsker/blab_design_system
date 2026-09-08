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

describe("BLab CSS token contract", () => {
  it("keeps representative CSS variables aligned with exported tokens", () => {
    expect(cssToken("--blab-color-primary")).toBe(BLabColors.primary.toLowerCase());
    expect(cssToken("--blab-color-error")).toBe(BLabColors.error.toLowerCase());
    expect(cssToken("--blab-space-xxl")).toBe(`${BLabSpacing.xxl}px`);
    expect(cssToken("--blab-radius-card")).toBe(`${BLabRadii.card}px`);
    expect(cssToken("--blab-elevation-surface")).toBe(BLabElevation.surface);
    expect(cssToken("--blab-glass-card-blur")).toBe(`${BLabGlass.cardBlur}px`);
    expect(cssToken("--blab-motion-press")).toBe(`${BLabMotion.press}ms`);
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
});
