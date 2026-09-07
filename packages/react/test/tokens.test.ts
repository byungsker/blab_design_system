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

describe("BLab token snapshots", () => {
  it("keeps the Flutter-aligned light/dark and typography contract", () => {
    expect({
      primary: BLabColors.primary,
      primaryAction: BLabColors.primaryAction,
      destructiveAction: BLabColors.destructiveAction,
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
      spacing: BLabSpacing,
      radii: BLabRadii,
      elevation: BLabElevation,
      glass: BLabGlass,
      motion: BLabMotion,
    }).toMatchInlineSnapshot(`
      {
        "dark": {
          "scaffold": "#121212",
          "surface": "#1E1E1E",
          "textPrimary": "#FFFFFF",
          "textSecondary": "rgba(255, 255, 255, 0.87)",
        },
        "destructiveAction": "#C5302D",
        "elevation": {
          "subtle": "0 1px 4px rgba(0, 0, 0, 0.08)",
          "surface": "0 8px 20px rgba(0, 0, 0, 0.15)",
        },
        "glass": {
          "cardBlur": 25,
          "darkBorder": "rgba(255, 255, 255, 0.15)",
          "darkFill": "rgba(255, 255, 255, 0.12)",
          "lightBorder": "rgba(0, 0, 0, 0.08)",
          "lightFill": "rgba(0, 0, 0, 0.08)",
          "overlayBlur": 20,
        },
        "light": {
          "scaffold": "#FAFAFA",
          "surface": "#FFFFFF",
          "textPrimary": "#000000",
          "textSecondary": "rgba(0, 0, 0, 0.87)",
        },
        "motion": {
          "longPressDelay": 500,
          "press": 150,
          "repeatInterval": 100,
          "surface": 180,
        },
        "primary": "#5B7FFF",
        "primaryAction": "#4A68D3",
        "radii": {
          "card": 16,
          "control": 12,
          "icon": 8,
          "pill": 100,
        },
        "spacing": {
          "accessoryHorizontal": 14,
          "bottomBarBottom": 22,
          "buttonHorizontal": 24,
          "buttonVertical": 14,
          "controlHorizontal": 16,
          "controlVertical": 14,
          "lg": 16,
          "md": 12,
          "sm": 8,
          "xl": 20,
          "xs": 4,
          "xxl": 24,
          "xxs": 2,
        },
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
