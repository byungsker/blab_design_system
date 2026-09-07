export type BLabColorMode = "light" | "dark";

export const BLabColors = {
  primary: "#5B7FFF",
  primaryAction: "#4A68D3",
  primaryLight: "#6B8AFF",
  success: "#10B981",
  successAlt: "#34C759",
  successBg: "#D1FAE5",
  error: "#FF3B30",
  errorAlt: "#EF4444",
  errorBg: "#FEE2E2",
  errorLight: "#FCA5A5",
  warning: "#FF9500",
  warningAlt: "#FFBE0B",
  info: "#4ECDC4",
  infoAlt: "#3498DB",
  destructive: "#FF6B6B",
  destructiveAction: "#C5302D",
  purple: "#9B59B6",
  chartColors: [
    "#5B7FFF",
    "#FF6B6B",
    "#4ECDC4",
    "#FFBE0B",
    "#9B59B6",
    "#3498DB",
    "#E74C3C",
    "#1ABC9C",
    "#F39C12",
    "#8E44AD",
  ],
  gold: "#FFD700",
  amber: "#FEF3C7",
  danger: "#DC2626",
  dangerAlt: "#D97706",
  light: {
    scaffold: "#FAFAFA",
    surface: "#FFFFFF",
    card: "#FFFFFF",
    elevated: "#F8F9FA",
    subtle: "#F5F7FF",
    textPrimary: "#000000",
    textSecondary: "rgba(0, 0, 0, 0.87)",
    textTertiary: "rgba(0, 0, 0, 0.60)",
  },
  dark: {
    scaffold: "#121212",
    surface: "#1E1E1E",
    card: "#1E1E1E",
    elevated: "#2C2C2E",
    subtle: "#2A2A2A",
    textPrimary: "#FFFFFF",
    textSecondary: "rgba(255, 255, 255, 0.87)",
    textTertiary: "rgba(255, 255, 255, 0.60)",
  },
} as const;

export const BLabTypography = {
  displayLarge: { fontSize: 32, fontWeight: 700, lineHeight: 1.2, letterSpacing: -0.5 },
  headlineLarge: { fontSize: 28, fontWeight: 700, lineHeight: 1.25, letterSpacing: -0.4 },
  titleLarge: { fontSize: 22, fontWeight: 700, lineHeight: 1.3, letterSpacing: -0.2 },
  titleMedium: { fontSize: 18, fontWeight: 600, lineHeight: 1.35 },
  bodyLarge: { fontSize: 16, fontWeight: 400, lineHeight: 1.5 },
  bodyMedium: { fontSize: 14, fontWeight: 400, lineHeight: 1.45 },
  labelLarge: { fontSize: 14, fontWeight: 600, lineHeight: 1.3 },
  labelSmall: { fontSize: 12, fontWeight: 500, lineHeight: 1.3 },
} as const;

export const BLabSpacing = {
  xxs: 2,
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  buttonVertical: 14,
  buttonHorizontal: 24,
  controlVertical: 14,
  controlHorizontal: 16,
  accessoryHorizontal: 14,
  bottomBarBottom: 22,
} as const;

export const BLabRadii = {
  control: 12,
  card: 16,
  pill: 100,
  icon: 8,
} as const;

export const BLabElevation = {
  subtle: "0 1px 4px rgba(0, 0, 0, 0.08)",
  surface: "0 8px 20px rgba(0, 0, 0, 0.15)",
} as const;

export const BLabGlass = {
  cardBlur: 25,
  overlayBlur: 20,
  lightFill: "rgba(0, 0, 0, 0.08)",
  darkFill: "rgba(255, 255, 255, 0.12)",
  lightBorder: "rgba(0, 0, 0, 0.08)",
  darkBorder: "rgba(255, 255, 255, 0.15)",
} as const;

export const BLabMotion = {
  press: 150,
  surface: 180,
  longPressDelay: 500,
  repeatInterval: 100,
} as const;
