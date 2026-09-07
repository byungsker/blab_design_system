import { useEffect, useRef } from "react";
import type { ReactNode } from "react";

import { BLabMotion } from "../tokens.js";

type BLabKeyboardAccessoryButtonProps = {
  readonly ariaLabel: string;
  readonly children: ReactNode;
  readonly enabled?: boolean;
  readonly onTap?: (() => void) | undefined;
  readonly supportLongPress?: boolean;
  readonly startRepeat: (action: () => void) => void;
  readonly stopRepeat: () => void;
};

function BLabKeyboardAccessoryButton({
  ariaLabel,
  children,
  enabled = true,
  onTap,
  supportLongPress = false,
  startRepeat,
  stopRepeat,
}: BLabKeyboardAccessoryButtonProps) {
  const longPressed = useRef(false);

  const handlePointerDown = () => {
    if (!enabled || !onTap || !supportLongPress) {
      return;
    }

    longPressed.current = false;
    startRepeat(() => {
      longPressed.current = true;
      onTap();
    });
  };

  const handlePointerEnd = () => {
    if (supportLongPress) {
      stopRepeat();
    }
  };

  const handleClick = () => {
    if (longPressed.current) {
      longPressed.current = false;
      return;
    }

    onTap?.();
  };

  return (
    <button
      className="blab-keyboard-accessory-bar__button"
      type="button"
      aria-label={ariaLabel}
      disabled={!enabled || !onTap}
      onClick={handleClick}
      onPointerDown={handlePointerDown}
      onPointerUp={handlePointerEnd}
      onPointerCancel={handlePointerEnd}
      onPointerLeave={handlePointerEnd}
    >
      {children}
    </button>
  );
}

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
    action();
    repeatTimer.current = setTimeout(() => {
      repeatTimer.current = setInterval(action, BLabMotion.repeatInterval);
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
              <BLabKeyboardAccessoryButton
                ariaLabel={upLabel}
                enabled={canGoUp}
                onTap={onUp}
                startRepeat={startRepeat}
                stopRepeat={stopRepeat}
              >
                ↑
              </BLabKeyboardAccessoryButton>
              <span className="blab-keyboard-accessory-bar__divider" aria-hidden="true" />
              <BLabKeyboardAccessoryButton
                ariaLabel={downLabel}
                enabled={canGoDown}
                onTap={onDown}
                startRepeat={startRepeat}
                stopRepeat={stopRepeat}
              >
                ↓
              </BLabKeyboardAccessoryButton>
            </>
          ) : null}
          {onCopy && copyLabel ? (
            <>
              <BLabKeyboardAccessoryButton
                ariaLabel={copyLabel}
                enabled={canCopy}
                onTap={onCopy}
                startRepeat={startRepeat}
                stopRepeat={stopRepeat}
              >
                ⧉
              </BLabKeyboardAccessoryButton>
              <span className="blab-keyboard-accessory-bar__divider" aria-hidden="true" />
            </>
          ) : null}
          {onClearAll && clearAllLabel ? (
            <BLabKeyboardAccessoryButton
              ariaLabel={clearAllLabel}
              enabled={canClearAll}
              onTap={onClearAll}
              startRepeat={startRepeat}
              stopRepeat={stopRepeat}
            >
              ⌫
            </BLabKeyboardAccessoryButton>
          ) : null}
        </div>
        <div className="blab-keyboard-accessory-bar__trailing">
          {onUndo && undoLabel ? (
            <>
              <BLabKeyboardAccessoryButton
                ariaLabel={undoLabel}
                enabled={canUndo}
                onTap={onUndo}
                supportLongPress
                startRepeat={startRepeat}
                stopRepeat={stopRepeat}
              >
                ↶
              </BLabKeyboardAccessoryButton>
              <span className="blab-keyboard-accessory-bar__divider" aria-hidden="true" />
            </>
          ) : null}
          {onRedo && redoLabel ? (
            <>
              <BLabKeyboardAccessoryButton
                ariaLabel={redoLabel}
                enabled={canRedo}
                onTap={onRedo}
                supportLongPress
                startRepeat={startRepeat}
                stopRepeat={stopRepeat}
              >
                ↷
              </BLabKeyboardAccessoryButton>
              <span className="blab-keyboard-accessory-bar__divider" aria-hidden="true" />
            </>
          ) : null}
          <BLabKeyboardAccessoryButton
            ariaLabel={doneLabel}
            onTap={onDone}
            startRepeat={startRepeat}
            stopRepeat={stopRepeat}
          >
            {icon ?? "⌨"}
          </BLabKeyboardAccessoryButton>
        </div>
      </div>
    </nav>
  );
}
