import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";

import { BLabColors, BLabElevation, BLabGlass, BLabMotion, BLabRadii, BLabSpacing } from "../src/index";

const css = readFileSync(new URL("../src/styles.css", import.meta.url), "utf8");

const cssToken = (name: string) => {
  const match = css.match(new RegExp(`${name}:\\s*([^;]+);`));
  return match?.[1]?.trim();
};

describe("BLab CSS token contract", () => {
  it("keeps representative CSS variables aligned with exported tokens", () => {
    expect(cssToken("--blab-color-primary")).toBe(BLabColors.primary.toLowerCase());
    expect(cssToken("--blab-color-primary-action")).toBe(BLabColors.primaryAction.toLowerCase());
    expect(cssToken("--blab-space-xxl")).toBe(`${BLabSpacing.xxl}px`);
    expect(cssToken("--blab-radius-card")).toBe(`${BLabRadii.card}px`);
    expect(cssToken("--blab-elevation-surface")).toBe(BLabElevation.surface);
    expect(cssToken("--blab-glass-card-blur")).toBe(`${BLabGlass.cardBlur}px`);
    expect(cssToken("--blab-motion-press")).toBe(`${BLabMotion.press}ms`);
  });
});
