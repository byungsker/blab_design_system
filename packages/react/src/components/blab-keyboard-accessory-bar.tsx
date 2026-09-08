"use client";

import { useEffect, useRef } from "react";
import type { ReactNode } from "react";

import { KeyboardAccessoryButton } from "./keyboard-accessory-button.js";
import { BLabMotion } from "../tokens.js";

type BLabKeyboardAccessoryBaseProps = {
  readonly onDone: () => void;
  readonly isDark?: boolean;
  readonly icon?: ReactNode;
  readonly doneLabel: string;
  readonly className?: string;
  readonly ariaLabel: string;
};

type BLabKeyboardAccessoryNavigationProps =
  | {
      readonly showNavigation?: false;
      readonly onUp?: () => void;
      readonly onDown?: () => void;
      readonly canGoUp?: boolean;
      readonly canGoDown?: boolean;
      readonly upLabel?: string;
      readonly downLabel?: string;
    }
  | {
      readonly showNavigation: true;
      readonly onUp?: () => void;
      readonly onDown?: () => void;
      readonly canGoUp?: boolean;
      readonly canGoDown?: boolean;
      readonly upLabel: string;
      readonly downLabel: string;
    };

type BLabKeyboardAccessoryActionCapabilities = {
  readonly canUndo?: boolean;
  readonly canRedo?: boolean;
  readonly canCopy?: boolean;
  readonly canClearAll?: boolean;
};

type BLabKeyboardAccessoryActionProps = BLabKeyboardAccessoryActionCapabilities &
  (
    | { readonly onUndo?: undefined; readonly undoLabel?: string }
    | { readonly onUndo: () => void; readonly undoLabel: string }
  ) &
  (
    | { readonly onRedo?: undefined; readonly redoLabel?: string }
    | { readonly onRedo: () => void; readonly redoLabel: string }
  ) &
  (
    | { readonly onCopy?: undefined; readonly copyLabel?: string }
    | { readonly onCopy: () => void; readonly copyLabel: string }
  ) &
  (
    | { readonly onClearAll?: undefined; readonly clearAllLabel?: string }
    | { readonly onClearAll: () => void; readonly clearAllLabel: string }
  );

export type BLabKeyboardAccessoryBarProps = BLabKeyboardAccessoryBaseProps &
  BLabKeyboardAccessoryNavigationProps &
  BLabKeyboardAccessoryActionProps;

export function BLabKeyboardAccessoryBar({
  onDone,
  isDark,
  icon,
  onUp,
  onDown,
  onUndo,
  onRedo,
  onCopy,
  onClearAll,
  showNavigation = false,
  canGoUp = true,
  canGoDown = true,
  canUndo = false,
  canRedo = false,
  canCopy = false,
  canClearAll = false,
  className,
  upLabel,
  downLabel,
  undoLabel,
  redoLabel,
  copyLabel,
  clearAllLabel,
  doneLabel,
  ariaLabel,
}: BLabKeyboardAccessoryBarProps) {
  const repeatTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);

  useEffect(
    () => () => {
      if (repeatTimer.current !== undefined) {
        clearTimeout(repeatTimer.current);
      }
    },
    [],
  );

  const stopRepeat = () => {
    if (repeatTimer.current !== undefined) {
      clearTimeout(repeatTimer.current);
      repeatTimer.current = undefined;
    }
  };

  const startRepeat = (action: () => void) => {
    stopRepeat();
    repeatTimer.current = setTimeout(() => {
      action();
      repeatTimer.current = setTimeout(() => {
        repeatTimer.current = setInterval(action, BLabMotion.repeatInterval);
      }, BLabMotion.longPressDelay);
    }, BLabMotion.longPressDelay);
  };

  const theme = isDark === undefined ? undefined : isDark ? "dark" : "light";
  const barClassName = [
    "blab-keyboard-accessory-bar",
    className ?? "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <nav className={barClassName} aria-label={ariaLabel} data-blab-theme={theme} data-blab-component="keyboard-accessory-bar">
      <div className="blab-keyboard-accessory-bar__surface">
        <div className="blab-keyboard-accessory-bar__leading">
          {showNavigation && upLabel && downLabel ? (
            <>
              <KeyboardAccessoryButton
                ariaLabel={upLabel}
                enabled={canGoUp}
                onTap={onUp}
                startRepeat={startRepeat}
                stopRepeat={stopRepeat}
              >
                ↑
              </KeyboardAccessoryButton>
              <span className="blab-keyboard-accessory-bar__divider" aria-hidden="true" />
              <KeyboardAccessoryButton
                ariaLabel={downLabel}
                enabled={canGoDown}
                onTap={onDown}
                startRepeat={startRepeat}
                stopRepeat={stopRepeat}
              >
                ↓
              </KeyboardAccessoryButton>
            </>
          ) : null}
          {onCopy && copyLabel ? (
            <>
              <KeyboardAccessoryButton
                ariaLabel={copyLabel}
                enabled={canCopy}
                onTap={onCopy}
                startRepeat={startRepeat}
                stopRepeat={stopRepeat}
              >
                ⧉
              </KeyboardAccessoryButton>
              <span className="blab-keyboard-accessory-bar__divider" aria-hidden="true" />
            </>
          ) : null}
          {onClearAll && clearAllLabel ? (
            <KeyboardAccessoryButton
              ariaLabel={clearAllLabel}
              enabled={canClearAll}
              onTap={onClearAll}
              startRepeat={startRepeat}
              stopRepeat={stopRepeat}
            >
              ⌫
            </KeyboardAccessoryButton>
          ) : null}
        </div>
        <div className="blab-keyboard-accessory-bar__trailing">
          {onUndo && undoLabel ? (
            <>
              <KeyboardAccessoryButton
                ariaLabel={undoLabel}
                enabled={canUndo}
                onTap={onUndo}
                supportLongPress
                startRepeat={startRepeat}
                stopRepeat={stopRepeat}
              >
                ↶
              </KeyboardAccessoryButton>
              <span className="blab-keyboard-accessory-bar__divider" aria-hidden="true" />
            </>
          ) : null}
          {onRedo && redoLabel ? (
            <>
              <KeyboardAccessoryButton
                ariaLabel={redoLabel}
                enabled={canRedo}
                onTap={onRedo}
                supportLongPress
                startRepeat={startRepeat}
                stopRepeat={stopRepeat}
              >
                ↷
              </KeyboardAccessoryButton>
              <span className="blab-keyboard-accessory-bar__divider" aria-hidden="true" />
            </>
          ) : null}
          <KeyboardAccessoryButton
            ariaLabel={doneLabel}
            onTap={onDone}
            startRepeat={startRepeat}
            stopRepeat={stopRepeat}
          >
            {icon ?? "⌨"}
          </KeyboardAccessoryButton>
        </div>
      </div>
    </nav>
  );
}
