"use client";

import { useRef } from "react";
import type { ReactNode } from "react";

export type KeyboardAccessoryButtonProps = {
  readonly ariaLabel: string;
  readonly children: ReactNode;
  readonly enabled?: boolean;
  readonly onTap?: (() => void) | undefined;
  readonly supportLongPress?: boolean;
  readonly startRepeat: (action: () => void) => void;
  readonly stopRepeat: () => void;
};

export function KeyboardAccessoryButton({
  ariaLabel,
  children,
  enabled = true,
  onTap,
  supportLongPress = false,
  startRepeat,
  stopRepeat,
}: KeyboardAccessoryButtonProps) {
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
