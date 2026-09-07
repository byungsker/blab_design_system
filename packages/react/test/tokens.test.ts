import { describe, expect, it } from "vitest";

import { BLabColors, BLabTypography } from "../src/index";

describe("BLab token snapshots", () => {
  it("keeps the Flutter-aligned light/dark and typography contract", () => {
    expect({
      primary: BLabColors.primary,
      light: {
        scaffold: BLabColors.light.scaffold,
        surface: BLabColors.light.surface,
        textPrimary: BLabColors.light.textPrimary,
        textSecondary: BLabColors.light.textSecondary,
      },
      dark: {
        scaffold: BLabColors.dark.scaffold,
        surface: BLabColors.dark.surface,
        textPrimary: BLabColors.dark.textPrimary,
        textSecondary: BLabColors.dark.textSecondary,
      },
      typography: {
        displayLarge: BLabTypography.displayLarge,
        titleMedium: BLabTypography.titleMedium,
        bodyMedium: BLabTypography.bodyMedium,
      },
    }).toMatchInlineSnapshot(`
      {
        "dark": {
          "scaffold": "#121212",
          "surface": "#1E1E1E",
          "textPrimary": "#FFFFFF",
          "textSecondary": "rgba(255, 255, 255, 0.87)",
        },
        "light": {
          "scaffold": "#FAFAFA",
          "surface": "#FFFFFF",
          "textPrimary": "#000000",
          "textSecondary": "rgba(0, 0, 0, 0.87)",
        },
        "primary": "#5B7FFF",
        "typography": {
          "bodyMedium": {
            "fontSize": 14,
            "fontWeight": 400,
            "lineHeight": 1.45,
          },
          "displayLarge": {
            "fontSize": 32,
            "fontWeight": 700,
            "letterSpacing": -0.5,
            "lineHeight": 1.2,
          },
          "titleMedium": {
            "fontSize": 18,
            "fontWeight": 600,
            "lineHeight": 1.35,
          },
        },
      }
    `);
  });
});
