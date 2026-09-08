import { readFileSync } from "node:fs";

import { describe, expect, it } from "vitest";

import {
  BLabColors,
  BLabTheme,
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
