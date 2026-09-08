"use client";

import { useEffect, useRef, useState } from "react";
import type { CSSProperties, KeyboardEventHandler, ReactNode } from "react";

type BLabPressableStyle = CSSProperties & {
  readonly "--blab-press-scale": string;
  readonly "--blab-press-brightness": string;
};

export type BLabPressableWrapperProps = {
  readonly children: ReactNode;
  readonly onTap: () => void;
  readonly onLongPress?: () => void;
  readonly scaleEnd?: number;
  readonly brightnessEnd?: number;
  readonly animationDuration?: number;
  readonly ariaLabel?: string;
  readonly className?: string;
  readonly style?: CSSProperties;
};

export function BLabPressableWrapper({
  children,
  onTap,
  onLongPress,
  scaleEnd = 0.96,
  brightnessEnd = 0.1,
  animationDuration = 150,
  ariaLabel,
  className,
  style,
}: BLabPressableWrapperProps) {
  const [pressed, setPressed] = useState(false);
  const longPressTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const longPressed = useRef(false);

  useEffect(
    () => () => {
      if (longPressTimer.current !== undefined) {
        clearTimeout(longPressTimer.current);
      }
    },
    [],
  );

  const clearTimer = () => {
    if (longPressTimer.current !== undefined) {
      clearTimeout(longPressTimer.current);
      longPressTimer.current = undefined;
    }
  };

  const handlePointerDown = () => {
    longPressed.current = false;
    setPressed(true);
    if (onLongPress) {
      longPressTimer.current = setTimeout(() => {
        longPressed.current = true;
        onLongPress();
      }, 500);
    }
  };

  const handlePointerUp = () => {
    clearTimer();
    setPressed(false);
    if (!longPressed.current) {
      onTap();
    }
    longPressed.current = false;
  };

  const handlePointerCancel = () => {
    clearTimer();
    setPressed(false);
    longPressed.current = false;
  };

  const handleKeyDown: KeyboardEventHandler<HTMLDivElement> = (event) => {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      onTap();
    }
  };

  const pressStyle: BLabPressableStyle = {
    ...style,
    "--blab-press-scale": `${scaleEnd}`,
    "--blab-press-brightness": `${1 + brightnessEnd}`,
    transitionDuration: `${animationDuration}ms`,
  };

  return (
    <div
      className={["blab-pressable", className ?? ""].filter(Boolean).join(" ")}
      style={pressStyle}
      role="button"
      tabIndex={0}
      aria-label={ariaLabel}
      data-blab-pressed={pressed ? "true" : "false"}
      onPointerDown={handlePointerDown}
      onPointerUp={handlePointerUp}
      onPointerCancel={handlePointerCancel}
      onPointerLeave={handlePointerCancel}
      onKeyDown={handleKeyDown}
    >
      {children}
    </div>
  );
}
