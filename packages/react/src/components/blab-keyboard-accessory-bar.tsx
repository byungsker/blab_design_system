import { useEffect, useRef } from "react";
import type { ReactNode } from "react";

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

export type BLabKeyboardAccessoryBarProps = {
  readonly onDone: () => void;
  readonly isDark?: boolean;
  readonly icon?: ReactNode;
  readonly onUp?: () => void;
  readonly onDown?: () => void;
  readonly onUndo?: () => void;
  readonly onRedo?: () => void;
  readonly onCopy?: () => void;
  readonly onClearAll?: () => void;
  readonly showNavigation?: boolean;
  readonly canGoUp?: boolean;
  readonly canGoDown?: boolean;
  readonly canUndo?: boolean;
  readonly canRedo?: boolean;
  readonly canCopy?: boolean;
  readonly canClearAll?: boolean;
  readonly doneLabel?: string;
  readonly upLabel?: string;
  readonly downLabel?: string;
  readonly undoLabel?: string;
  readonly redoLabel?: string;
  readonly copyLabel?: string;
  readonly clearAllLabel?: string;
  readonly className?: string;
  readonly ariaLabel?: string;
};

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
  doneLabel = "Done",
  upLabel = "Move up",
  downLabel = "Move down",
  undoLabel = "Undo",
  redoLabel = "Redo",
  copyLabel = "Copy",
  clearAllLabel = "Clear all",
  className,
  ariaLabel = "Keyboard accessory",
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
      repeatTimer.current = setInterval(action, 100);
    }, 500);
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
          {showNavigation ? (
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
          {onCopy ? (
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
          {onClearAll ? (
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
          {onUndo ? (
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
          {onRedo ? (
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
