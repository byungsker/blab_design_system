import { readFileSync } from "node:fs";

import { describe, expect, it } from "vitest";

import {
  BLabColors,
  BLabElevation,
  BLabGlass,
  BLabMotion,
  BLabRadii,
  BLabSpacing,
  BLabTheme,
  BLabTypography,
} from "../src/index";

const flutterColorsSource = readFileSync(
  new URL("../../../lib/src/theme/app_colors.dart", import.meta.url),
  "utf8",
);

const flutterColor = (name: string) => {
  const match = flutterColorsSource.match(
    new RegExp(`static const Color ${name} = Color\\(0xFF([0-9A-F]{6})\\);`),
  );
  const value = match?.[1];
  if (!value) {
    throw new Error(`Flutter color ${name} is not defined as a hex constant`);
  }
  return `#${value}`;
};

describe("BLab token contract", () => {
  it("keeps semantic colors aligned with the Flutter source", () => {
    expect(BLabColors.primary).toBe(flutterColor("primary"));
    expect(BLabColors.error).toBe(flutterColor("error"));
    expect(BLabColors.destructive).toBe(flutterColor("destructive"));
    expect(BLabColors.light.scaffold).toBe(flutterColor("scaffoldLight"));
    expect(BLabColors.dark.scaffold).toBe(flutterColor("scaffoldDark"));
    expect(BLabColors.dark.elevated).toBe(flutterColor("elevatedDark"));
  });

  it("keeps shared layout, type, glass and motion tokens stable", () => {
    expect(BLabTypography.displayLarge).toEqual({ fontSize: 32, fontWeight: 700, lineHeight: 1.2, letterSpacing: -0.5 });
    expect(BLabTypography.titleMedium).toEqual({ fontSize: 18, fontWeight: 600, lineHeight: 1.35 });
    expect(BLabTypography.bodyMedium).toEqual({ fontSize: 14, fontWeight: 400, lineHeight: 1.45 });
    expect(BLabSpacing).toMatchObject({ buttonVertical: 14, buttonHorizontal: 24, controlVertical: 14, controlHorizontal: 16 });
    expect(BLabRadii).toEqual({ control: 12, card: 16, pill: 100, icon: 8 });
    expect(BLabElevation).toEqual({ subtle: "0 1px 4px rgba(0, 0, 0, 0.08)", surface: "0 8px 20px rgba(0, 0, 0, 0.15)" });
    expect(BLabGlass).toEqual({
      cardBlur: 25,
      overlayBlur: 20,
      lightFill: "rgba(0, 0, 0, 0.08)",
      darkFill: "rgba(255, 255, 255, 0.12)",
      lightBorder: "rgba(0, 0, 0, 0.08)",
      darkBorder: "rgba(255, 255, 255, 0.15)",
    });
    expect(BLabMotion).toEqual({ press: 150, surface: 180, longPressDelay: 500, repeatInterval: 100 });
  });

  it("keeps Flutter public grey helpers and theme mappings available", () => {
    expect(BLabColors.grey50Light).toBe("#F5F5F5");
    expect(BLabColors.grey100Light).toBe("#F3F4F6");
    expect(BLabColors.grey200Light).toBe("#E5E7EB");
    expect(BLabColors.grey(50, "light")).toBe("#FAFAFA");
    expect(BLabColors.grey(100, "dark")).toBe("#424242");
    expect(BLabColors.grey(850, "dark")).toBe("#FAFAFA");
    expect(BLabColors.scaffold("dark")).toBe(BLabTheme.dark.scaffoldBackgroundColor);
    expect(BLabTheme.light.inputDecoration.focusedBorder).toEqual({ color: BLabColors.primary, width: 2 });
    expect(BLabTheme.dark.elevatedButton.minHeight).toBe(52);
  });
});
